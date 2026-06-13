import json
import secrets
import logging
from datetime import datetime

from odoo import api, fields, models
from odoo.exceptions import UserError

_logger = logging.getLogger(__name__)


class PosipvSyncService(models.AbstractModel):
    _name = "posipv.sync.service"
    _description = "Servicio de sincronización POSIPV"

    def _generate_api_key(self):
        return secrets.token_hex(24)

    def _json_dumps(self, payload):
        return json.dumps(payload or {}, ensure_ascii=False, default=str)

    def _json_loads_dict(self, payload):
        if not payload:
            return {}
        try:
            data = json.loads(payload)
        except Exception:
            return {}
        return data if isinstance(data, dict) else {}

    def _now(self):
        return fields.Datetime.now()

    def _to_float(self, value):
        try:
            return float(value or 0.0)
        except (TypeError, ValueError):
            return 0.0

    def _to_datetime(self, value):
        if not value:
            return False
        if isinstance(value, fields.Datetime):
            return value
        if isinstance(value, datetime):
            return value
        if isinstance(value, str):
            clean = value.strip()
            if not clean:
                return False
            candidates = [clean]
            if clean.endswith("Z"):
                candidates.append("%s+00:00" % clean[:-1])
            if "T" in clean:
                candidates.append(clean.replace("T", " "))
                if clean.endswith("Z"):
                    candidates.append("%s+00:00" % clean[:-1].replace("T", " "))
            for candidate in candidates:
                try:
                    return fields.Datetime.to_datetime(candidate)
                except Exception:
                    continue
                try:
                    return datetime.fromisoformat(candidate)
                except Exception:
                    continue
        try:
            return fields.Datetime.to_datetime(value)
        except Exception:
            return False

    def _clean(self, value):
        return (value or "").strip() if isinstance(value, str) else value

    def _mask_secret(self, value):
        clean = self._clean(value) or ""
        if not clean:
            return "<vacío>"
        if len(clean) <= 4:
            return "*" * len(clean)
        return "%s***%s" % (clean[:2], clean[-2:])

    def _extract_uuid(self, payload, fallback=None):
        for key in ("external_uuid", "id", "uuid"):
            value = self._clean(payload.get(key))
            if value:
                return value
        if fallback:
            return fallback
        raise UserError("El payload no contiene un identificador externo.")

    def _get_backend_settings(self):
        settings_model = self.env["posipv.backend.settings"].sudo()
        active_settings = settings_model.search(
            [("active", "=", True)],
            order="write_date desc, id desc",
        )
        if len(active_settings) > 1:
            _logger.warning(
                "POSIPV backend settings: multiple active records detected db=%s ids=%s. Using id=%s",
                self.env.cr.dbname,
                active_settings.ids,
                active_settings[:1].id,
            )
        settings = active_settings[:1]
        if not settings:
            settings = settings_model.search([], order="write_date desc, id desc", limit=1)
        if not settings:
            settings = settings_model.create(
                {"name": "Servidor POSIPV"}
            )
        return settings

    def _log_sync(
        self,
        direction,
        endpoint,
        status,
        device=False,
        request_count=0,
        record_count=0,
        response=None,
        error_message=None,
    ):
        self.env["posipv.sync.log"].sudo().create(
            {
                "name": "%s - %s" % (direction.upper(), endpoint),
                "device_id": device.id if device else False,
                "direction": direction,
                "endpoint": endpoint,
                "status": status,
                "started_at": self._now(),
                "finished_at": self._now(),
                "request_count": request_count,
                "record_count": record_count,
                "response_json": self._json_dumps(response),
                "error_message": error_message,
            }
        )

    def _authenticate_device(self, device_uuid, api_key):
        device_uuid = self._clean(device_uuid)
        api_key = self._clean(api_key)
        if not device_uuid or not api_key:
            raise UserError("Faltan credenciales del dispositivo.")
        device = (
            self.env["posipv.sync.device"]
            .sudo()
            .search(
                [
                    ("device_uuid", "=", device_uuid),
                    ("api_key", "=", api_key),
                    ("active", "=", True),
                    ("sync_enabled", "=", True),
                ],
                limit=1,
            )
        )
        if not device:
            raise UserError("Dispositivo no autorizado o API key inválida.")
        device.sudo().write({"last_seen_at": self._now()})
        return device

    @api.model
    def ping(self):
        self._log_sync(
            direction="test",
            endpoint="/posipv/api/v1/ping",
            status="success",
            response={"ok": True},
        )
        return {
            "ok": True,
            "message": "Conexión con Odoo disponible.",
            "server_version": self.env["ir.module.module"].sudo().search(
                [("name", "=", "base")], limit=1
            ).latest_version
            or "18.0",
            "server_time": self._now().isoformat(),
            "database": self.env.cr.dbname,
        }

    @api.model
    def register_device(self, payload):
        settings = self._get_backend_settings()
        if not settings.allow_device_registration:
            raise UserError("El registro de dispositivos está desactivado.")
        bootstrap_token = self._clean(payload.get("bootstrap_token"))
        if bootstrap_token != settings.bootstrap_token:
            _logger.warning(
                "POSIPV register_device token mismatch db=%s settings_id=%s expected=%s received=%s device_uuid=%s",
                self.env.cr.dbname,
                settings.id,
                self._mask_secret(settings.bootstrap_token),
                self._mask_secret(bootstrap_token),
                self._clean(payload.get("device_uuid")) or "<sin-uuid>",
            )
            raise UserError("Token de arranque inválido.")
        device_uuid = self._clean(payload.get("device_uuid"))
        device_label = self._clean(payload.get("device_label")) or device_uuid
        if not device_uuid:
            raise UserError("Debes indicar el UUID del dispositivo.")

        device = (
            self.env["posipv.sync.device"]
            .sudo()
            .search([("device_uuid", "=", device_uuid)], limit=1)
        )
        values = {
            "name": device_label,
            "device_uuid": device_uuid,
            "app_version": self._clean(payload.get("app_version")),
            "company_id": settings.company_id.id or self.env.company.id,
            "last_seen_at": self._now(),
        }
        if device:
            device.sudo().write(values)
        else:
            values["api_key"] = self._generate_api_key()
            device = self.env["posipv.sync.device"].sudo().create(values)

        result = {
            "ok": True,
            "message": "Dispositivo registrado correctamente.",
            "device_uuid": device.device_uuid,
            "api_key": device.api_key,
        }
        self._log_sync(
            direction="register",
            endpoint="/posipv/api/v1/device/register",
            status="success",
            device=device,
            request_count=1,
            record_count=1,
            response=result,
        )
        return result

    @api.model
    def export_master_data(self, device_uuid, api_key):
        settings = self._get_backend_settings()
        if not settings.allow_pull:
            raise UserError("La descarga de catálogos está desactivada.")
        device = self._authenticate_device(device_uuid, api_key)

        products = self.env["product.product"].sudo().search([("active", "=", True)])
        customers = self.env["res.partner"].sudo().search(
            [("customer_rank", ">", 0), ("active", "=", True)]
        )
        employees = self.env["hr.employee"].sudo().search([("active", "=", True)])
        warehouses = self.env["stock.warehouse"].sudo().search([("active", "=", True)])
        terminals = self.env["pos.config"].sudo().search([("active", "=", True)])

        payload = {
            "ok": True,
            "message": "Catálogos exportados correctamente.",
            "products": [
                {
                    "id": record.id,
                    "name": record.display_name,
                    "sku": record.default_code,
                    "barcode": record.barcode,
                    "sale_price": record.lst_price,
                    "cost_price": record.standard_price,
                    "category": record.categ_id.display_name,
                    "product_type": getattr(record, "detailed_type", False) or getattr(record, "type", False),
                    "unit_measure": record.uom_id.name,
                    "currency_code": self.env.company.currency_id.name,
                    "active": record.active,
                    "updated_at": record.write_date.isoformat() if record.write_date else False,
                }
                for record in products
            ],
            "customers": [
                {
                    "id": record.id,
                    "name": record.display_name,
                    "code": "ODOO-C-%s" % record.id,
                    "phone": record.phone,
                    "email": record.email,
                    "vat": record.vat,
                    "street": record.street,
                    "active": record.active,
                    "updated_at": record.write_date.isoformat() if record.write_date else False,
                }
                for record in customers
            ],
            "employees": [
                {
                    "id": record.id,
                    "name": record.name,
                    "code": "ODOO-E-%s" % record.id,
                    "work_email": record.work_email,
                    "identification_id": record.identification_id,
                    "active": record.active,
                    "updated_at": record.write_date.isoformat() if record.write_date else False,
                }
                for record in employees
            ],
            "warehouses": [
                {
                    "id": record.id,
                    "name": record.name,
                    "code": record.code,
                    "warehouse_type": "Central",
                    "active": record.active,
                    "updated_at": record.write_date.isoformat() if record.write_date else False,
                }
                for record in warehouses
            ],
            "terminals": [
                {
                    "id": record.id,
                    "code": record.name,
                    "name": record.name,
                    "warehouse_id": record.picking_type_id.warehouse_id.id if record.picking_type_id and record.picking_type_id.warehouse_id else False,
                    "warehouse_name": record.picking_type_id.warehouse_id.name if record.picking_type_id and record.picking_type_id.warehouse_id else False,
                    "currency_code": ((getattr(record, "currency_id", False) and record.currency_id.name) or self.env.company.currency_id.name),
                    "payment_methods": ["cash"],
                    "active": record.active,
                    "updated_at": record.write_date.isoformat() if record.write_date else False,
                }
                for record in terminals
            ],
        }
        device.sudo().write(
            {
                "pull_count": device.pull_count + 1,
                "last_sync_at": self._now(),
            }
        )
        settings.sudo().write({"last_master_pull_at": self._now()})
        self._log_sync(
            direction="pull",
            endpoint="/posipv/api/v1/pull/master-data",
            status="success",
            device=device,
            request_count=1,
            record_count=sum(len(payload[key]) for key in ("products", "customers", "employees", "warehouses", "terminals")),
            response={"message": payload["message"]},
        )
        return payload

    @api.model
    def export_work_orders(self, device_uuid, api_key):
        settings = self._get_backend_settings()
        if not settings.allow_pull:
            raise UserError("La descarga de pedidos está desactivada.")
        device = self._authenticate_device(device_uuid, api_key)

        records = (
            self.env["posipv.work.order"]
            .sudo()
            .search([], order="source_updated_at desc, received_at desc, id desc")
        )
        work_orders = []
        for record in records:
            payload = self._json_loads_dict(record.payload_json)
            payload.update(
                {
                    "id": payload.get("id") or record.external_uuid,
                    "folio": payload.get("folio") or record.folio,
                    "customer_name": payload.get("customer_name")
                    or record.customer_name,
                    "title": payload.get("title") or record.title,
                    "description": payload.get("description")
                    or record.description,
                    "status": payload.get("status") or record.status,
                    "payment_status": payload.get("payment_status")
                    or record.payment_status,
                    "priority": payload.get("priority") or record.priority,
                    "work_type": payload.get("work_type") or record.work_type,
                    "assigned_employee_name": payload.get(
                        "assigned_employee_name"
                    )
                    or record.assigned_employee_name,
                    "qty": payload.get("qty") or record.qty,
                    "unit_label": payload.get("unit_label") or record.unit_label,
                    "created_at": payload.get("created_at")
                    or (
                        record.source_created_at.isoformat()
                        if record.source_created_at
                        else False
                    ),
                    "updated_at": payload.get("updated_at")
                    or (
                        record.source_updated_at.isoformat()
                        if record.source_updated_at
                        else False
                    ),
                    "due_at": payload.get("due_at")
                    or (record.due_at.isoformat() if record.due_at else False),
                    "completed_at": payload.get("completed_at")
                    or (
                        record.completed_at.isoformat()
                        if record.completed_at
                        else False
                    ),
                    "delivered_at": payload.get("delivered_at")
                    or (
                        record.delivered_at.isoformat()
                        if record.delivered_at
                        else False
                    ),
                    "paid_at": payload.get("paid_at")
                    or (record.paid_at.isoformat() if record.paid_at else False),
                    "note": payload.get("note") or record.note,
                    "quoted_totals": payload.get("quoted_totals")
                    or self._json_loads_list(record.quoted_totals_json),
                    "quoted_requested_lines": payload.get("quoted_requested_lines")
                    or self._json_loads_list(record.quoted_requested_lines_json),
                    "quoted_payment_variants": payload.get("quoted_payment_variants")
                    or self._json_loads_list(record.quoted_payment_variants_json),
                    "pricing_snapshot": payload.get("pricing_snapshot")
                    or self._json_loads_dict(record.pricing_snapshot_json),
                    "payment_lines": payload.get("payment_lines")
                    or self._json_loads_list(record.payment_lines_json),
                    "is_active": record.active,
                }
            )
            work_orders.append(payload)

        result = {
            "ok": True,
            "message": "Pedidos exportados correctamente.",
            "work_orders": work_orders,
        }
        device.sudo().write(
            {
                "pull_count": device.pull_count + 1,
                "last_sync_at": self._now(),
            }
        )
        self._log_sync(
            direction="pull",
            endpoint="/posipv/api/v1/pull/work-orders",
            status="success",
            device=device,
            request_count=1,
            record_count=len(work_orders),
            response={"message": result["message"], "count": len(work_orders)},
        )
        return result

    @api.model
    def receive_batch(self, device_uuid, api_key, payload):
        settings = self._get_backend_settings()
        if not settings.allow_push:
            raise UserError("La recepción de datos desde la app está desactivada.")
        device = self._authenticate_device(device_uuid, api_key)
        batch = payload.get("batch") or {}
        accepted = 0
        failed = 0
        for entity_type, entries in batch.items():
            for entry in entries or []:
                try:
                    item_payload = entry.get("payload") if isinstance(entry, dict) else entry
                    self._dispatch_upsert(entity_type, item_payload, device)
                    accepted += 1
                except Exception:
                    failed += 1
        device.sudo().write(
            {
                "push_count": device.push_count + 1,
                "last_sync_at": self._now(),
            }
        )
        settings.sudo().write({"last_batch_received_at": self._now()})
        result = {
            "ok": failed == 0,
            "message": "Batch procesado. %s aceptados, %s fallidos." % (accepted, failed),
            "accepted_records": accepted,
            "failed_records": failed,
        }
        self._log_sync(
            direction="push",
            endpoint="/posipv/api/v1/push/batch",
            status="warning" if failed else "success",
            device=device,
            request_count=1,
            record_count=accepted + failed,
            response=result,
            error_message=False if failed == 0 else "Algunas entradas no pudieron procesarse.",
        )
        return result

    def _dispatch_upsert(self, entity_type, payload, device):
        mapping = {
            "products": self._upsert_product,
            "customers": self._upsert_customer,
            "employees": self._upsert_employee,
            "warehouses": self._upsert_warehouse,
            "terminals": self._upsert_terminal,
            "sales": self._upsert_sale,
            "stock_movements": self._upsert_stock_movement,
            "work_orders": self._upsert_work_order,
        }
        handler = mapping.get(entity_type)
        if not handler:
            raise UserError("Tipo de entidad no soportado: %s" % entity_type)
        return handler(payload or {}, device)

    def _prepare_common_values(self, payload, device):
        return {
            "name": self._clean(payload.get("name")) or self._clean(payload.get("title")) or self._clean(payload.get("folio")) or "Registro POSIPV",
            "device_id": device.id if device else False,
            "source_updated_at": self._to_datetime(payload.get("updated_at") or payload.get("source_updated_at")),
            "received_at": self._now(),
            "payload_json": self._json_dumps(payload),
            "active": payload.get("is_active", True) if "is_active" in payload else payload.get("active", True),
        }

    def _upsert_product(self, payload, device):
        model = self.env["posipv.catalog.product"].sudo()
        external_uuid = self._extract_uuid(payload)
        record = model.search([("external_uuid", "=", external_uuid)], limit=1)
        values = self._prepare_common_values(payload, device)
        values.update(
            {
                "external_uuid": external_uuid,
                "sku": self._clean(payload.get("sku")),
                "barcode": self._clean(payload.get("barcode")),
                "sale_price": self._to_float(payload.get("sale_price") or payload.get("price")),
                "cost_price": self._to_float(payload.get("cost_price")),
                "currency_code": self._clean(payload.get("currency_code")),
                "category_name": self._clean(payload.get("category")),
                "product_type": self._clean(payload.get("product_type")),
                "unit_measure": self._clean(payload.get("unit_measure")),
                "order_costing_mode": self._clean(payload.get("order_costing_mode")),
            }
        )
        record.write(values) if record else model.create(values)

    def _upsert_customer(self, payload, device):
        model = self.env["posipv.catalog.customer"].sudo()
        external_uuid = self._extract_uuid(payload)
        record = model.search([("external_uuid", "=", external_uuid)], limit=1)
        values = self._prepare_common_values(payload, device)
        values.update(
            {
                "external_uuid": external_uuid,
                "code": self._clean(payload.get("code")),
                "identity_number": self._clean(payload.get("identity_number") or payload.get("vat")),
                "phone": self._clean(payload.get("phone")),
                "email": self._clean(payload.get("email")),
                "address": self._clean(payload.get("address") or payload.get("street")),
                "company_name": self._clean(payload.get("company")),
                "customer_type": self._clean(payload.get("customer_type")),
                "is_vip": bool(payload.get("is_vip")),
                "discount_bps": int(payload.get("discount_bps") or 0),
            }
        )
        record.write(values) if record else model.create(values)

    def _upsert_employee(self, payload, device):
        model = self.env["posipv.catalog.employee"].sudo()
        external_uuid = self._extract_uuid(payload)
        record = model.search([("external_uuid", "=", external_uuid)], limit=1)
        values = self._prepare_common_values(payload, device)
        values.update(
            {
                "external_uuid": external_uuid,
                "code": self._clean(payload.get("code")),
                "identity_number": self._clean(payload.get("identity_number")),
                "sex": self._clean(payload.get("sex")),
                "associated_username": self._clean(payload.get("associated_username")),
            }
        )
        record.write(values) if record else model.create(values)

    def _upsert_warehouse(self, payload, device):
        model = self.env["posipv.catalog.warehouse"].sudo()
        external_uuid = self._extract_uuid(payload)
        record = model.search([("external_uuid", "=", external_uuid)], limit=1)
        values = self._prepare_common_values(payload, device)
        values.update(
            {
                "external_uuid": external_uuid,
                "warehouse_type": self._clean(payload.get("warehouse_type")),
            }
        )
        record.write(values) if record else model.create(values)

    def _upsert_terminal(self, payload, device):
        model = self.env["posipv.catalog.terminal"].sudo()
        external_uuid = self._extract_uuid(payload)
        record = model.search([("external_uuid", "=", external_uuid)], limit=1)
        values = self._prepare_common_values(payload, device)
        values.update(
            {
                "external_uuid": external_uuid,
                "code": self._clean(payload.get("code")),
                "warehouse_external_uuid": self._clean(payload.get("warehouse_id") or payload.get("warehouse_external_uuid")),
                "currency_code": self._clean(payload.get("currency_code")),
                "payment_methods_json": self._json_dumps(payload.get("payment_methods")),
            }
        )
        record.write(values) if record else model.create(values)

    def _upsert_sale(self, payload, device):
        model = self.env["posipv.sale"].sudo()
        external_uuid = self._extract_uuid(payload)
        record = model.search([("external_uuid", "=", external_uuid)], limit=1)
        values = self._prepare_common_values(payload, device)
        values.update(
            {
                "external_uuid": external_uuid,
                "folio": self._clean(payload.get("folio")) or external_uuid,
                "warehouse_name": self._clean(payload.get("warehouse_name")),
                "terminal_name": self._clean(payload.get("terminal_name")),
                "cashier_name": self._clean(payload.get("cashier_name")),
                "customer_name": self._clean(payload.get("customer_name")),
                "subtotal_amount": self._to_float(payload.get("subtotal")),
                "tax_amount": self._to_float(payload.get("tax")),
                "total_amount": self._to_float(payload.get("total")),
                "status": self._clean(payload.get("status")),
                "sale_datetime": self._to_datetime(payload.get("created_at") or payload.get("sale_datetime")),
            }
        )
        if record:
            record.write(values)
        else:
            record = model.create(values)
        line_commands = [(5, 0, 0)]
        for line in payload.get("lines", []) or []:
            line_commands.append(
                (
                    0,
                    0,
                    {
                        "external_uuid": self._clean(line.get("id")),
                        "product_name": self._clean(line.get("product_name")),
                        "product_sku": self._clean(line.get("product_sku")),
                        "qty": self._to_float(line.get("qty")),
                        "unit_price": self._to_float(line.get("unit_price")),
                        "unit_cost": self._to_float(line.get("unit_cost")),
                        "tax_rate_bps": int(line.get("tax_rate_bps") or 0),
                        "line_total": self._to_float(line.get("line_total")),
                        "payload_json": self._json_dumps(line),
                    },
                )
            )
        payment_commands = [(5, 0, 0)]
        for payment in payload.get("payments", []) or []:
            payment_commands.append(
                (
                    0,
                    0,
                    {
                        "external_uuid": self._clean(payment.get("id")),
                        "method": self._clean(payment.get("method")) or "cash",
                        "amount": self._to_float(payment.get("amount")),
                        "transaction_id": self._clean(payment.get("transaction_id")),
                        "source_currency_code": self._clean(payment.get("source_currency_code")),
                        "source_amount": self._to_float(payment.get("source_amount")),
                        "payment_datetime": self._to_datetime(payment.get("created_at") or payment.get("payment_datetime")),
                        "payload_json": self._json_dumps(payment),
                    },
                )
            )
        record.write({"line_ids": line_commands, "payment_ids": payment_commands})

    def _upsert_stock_movement(self, payload, device):
        model = self.env["posipv.stock.movement"].sudo()
        external_uuid = self._extract_uuid(payload)
        record = model.search([("external_uuid", "=", external_uuid)], limit=1)
        values = self._prepare_common_values(payload, device)
        values.update(
            {
                "external_uuid": external_uuid,
                "product_name": self._clean(payload.get("product_name")),
                "product_sku": self._clean(payload.get("product_sku")),
                "warehouse_name": self._clean(payload.get("warehouse_name")),
                "movement_type": self._clean(payload.get("type")),
                "qty": self._to_float(payload.get("qty")),
                "reason_code": self._clean(payload.get("reason_code")),
                "movement_source": self._clean(payload.get("movement_source")),
                "ref_type": self._clean(payload.get("ref_type")),
                "ref_id": self._clean(payload.get("ref_id")),
                "is_voided": bool(payload.get("is_voided")),
                "created_by_name": self._clean(payload.get("created_by_name")),
                "movement_datetime": self._to_datetime(payload.get("created_at") or payload.get("movement_datetime")),
            }
        )
        record.write(values) if record else model.create(values)

    def _upsert_work_order(self, payload, device):
        model = self.env["posipv.work.order"].sudo()
        external_uuid = self._extract_uuid(payload)
        record = model.search([("external_uuid", "=", external_uuid)], limit=1)
        values = self._prepare_common_values(payload, device)
        values.update(
            {
                "external_uuid": external_uuid,
                "folio": self._clean(payload.get("folio")) or external_uuid,
                "customer_name": self._clean(payload.get("customer_name")),
                "title": self._clean(payload.get("title")) or self._clean(payload.get("name")) or external_uuid,
                "description": payload.get("description"),
                "status": self._clean(payload.get("status")),
                "payment_status": self._clean(payload.get("payment_status")),
                "priority": self._clean(payload.get("priority")),
                "work_type": self._clean(payload.get("work_type")),
                "assigned_employee_name": self._clean(payload.get("assigned_employee_name")),
                "qty": self._to_float(payload.get("qty")),
                "unit_label": self._clean(payload.get("unit_label")),
                "due_at": self._to_datetime(payload.get("due_at")),
                "source_created_at": self._to_datetime(payload.get("created_at")),
                "source_updated_at": self._to_datetime(payload.get("updated_at") or payload.get("source_updated_at")),
                "completed_at": self._to_datetime(payload.get("completed_at")),
                "delivered_at": self._to_datetime(payload.get("delivered_at")),
                "paid_at": self._to_datetime(payload.get("paid_at")),
                "note": payload.get("note"),
                "items_json": self._json_dumps(payload.get("items")),
                "assignments_json": self._json_dumps(payload.get("assignments")),
                "quoted_totals_json": self._json_dumps(payload.get("quoted_totals")),
                "quoted_requested_lines_json": self._json_dumps(payload.get("quoted_requested_lines")),
                "quoted_payment_variants_json": self._json_dumps(payload.get("quoted_payment_variants")),
                "pricing_snapshot_json": self._json_dumps(payload.get("pricing_snapshot")),
                "payment_lines_json": self._json_dumps(payload.get("payment_lines")),
            }
        )
        if record:
            record.write(values)
        else:
            record = model.create(values)
        task_commands = [(5, 0, 0)]
        for task in payload.get("tasks", []) or []:
            task_commands.append(
                (
                    0,
                    0,
                    {
                        "external_uuid": self._clean(task.get("id")),
                        "title": self._clean(task.get("title")) or "Trabajo",
                        "description": task.get("description"),
                        "materials_json": self._json_dumps(task.get("materials")),
                        "waste_materials_json": self._json_dumps(task.get("waste_materials")),
                        "workers_json": self._json_dumps(task.get("workers")),
                        "image_paths_json": self._json_dumps(task.get("image_paths")),
                        "created_at": self._to_datetime(task.get("created_at")),
                        "payload_json": self._json_dumps(task),
                    },
                )
            )
        record.write({"task_ids": task_commands})
