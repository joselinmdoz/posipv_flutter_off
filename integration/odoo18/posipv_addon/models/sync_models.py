import json

from odoo import api, fields, models


class PosipvBackendSettings(models.Model):
    _name = "posipv.backend.settings"
    _description = "Configuración backend POSIPV"

    name = fields.Char(string="Nombre", default="Servidor POSIPV", required=True)
    active = fields.Boolean(string="Activo", default=True)
    show_bootstrap_token = fields.Boolean(
        string="Mostrar token de arranque",
        default=False,
        copy=False,
    )
    bootstrap_token = fields.Char(
        string="Token de arranque",
        required=True,
        copy=False,
        default=lambda self: self.env["posipv.sync.service"]._generate_api_key(),
        help="Token temporal usado para registrar nuevos dispositivos.",
    )
    allow_device_registration = fields.Boolean(
        string="Permitir registro de dispositivos",
        default=True,
    )
    allow_push = fields.Boolean(string="Permitir subida de datos", default=True)
    allow_pull = fields.Boolean(
        string="Permitir descarga de catálogos",
        default=True,
    )
    company_id = fields.Many2one(
        "res.company",
        string="Compañía por defecto",
        default=lambda self: self.env.company.id,
    )
    notes = fields.Text(string="Notas")
    last_batch_received_at = fields.Datetime(
        string="Último lote recibido",
        readonly=True,
    )
    last_master_pull_at = fields.Datetime(
        string="Última descarga de catálogos",
        readonly=True,
    )

    @api.model_create_multi
    def create(self, vals_list):
        records = super().create(vals_list)
        records._ensure_single_active_backend()
        return records

    def write(self, vals):
        result = super().write(vals)
        if "active" in vals:
            self._ensure_single_active_backend()
        return result

    def _ensure_single_active_backend(self):
        for record in self.filtered("active"):
            others = self.sudo().search(
                [
                    ("id", "!=", record.id),
                    ("active", "=", True),
                ]
            )
            if others:
                others.write({"active": False})

    def action_show_bootstrap_token(self):
        self.ensure_one()
        self.show_bootstrap_token = True

    def action_hide_bootstrap_token(self):
        self.ensure_one()
        self.show_bootstrap_token = False

    def action_regenerate_bootstrap_token(self):
        self.ensure_one()
        new_token = self.env["posipv.sync.service"]._generate_api_key()
        self.write(
            {
                "bootstrap_token": new_token,
                "show_bootstrap_token": True,
            }
        )
        return {
            "type": "ir.actions.client",
            "tag": "display_notification",
            "params": {
                "title": "Token regenerado",
                "message": "Se generó un nuevo token de arranque. Copia el valor nuevo antes de registrar otros dispositivos.",
                "type": "success",
                "sticky": False,
            },
        }


class PosipvSyncDevice(models.Model):
    _name = "posipv.sync.device"
    _description = "Dispositivo POSIPV"
    _order = "last_seen_at desc, id desc"

    name = fields.Char(string="Nombre del dispositivo", required=True)
    device_uuid = fields.Char(string="UUID del dispositivo", required=True, index=True)
    api_key = fields.Char(string="Clave API", required=True, copy=False)
    app_version = fields.Char(string="Versión de la app")
    sync_enabled = fields.Boolean(string="Sincronización habilitada", default=True)
    active = fields.Boolean(string="Activo", default=True)
    company_id = fields.Many2one(
        "res.company",
        string="Compañía",
        default=lambda self: self.env.company.id,
    )
    notes = fields.Text(string="Notas")
    last_seen_at = fields.Datetime(string="Última actividad", readonly=True)
    last_sync_at = fields.Datetime(string="Última sincronización", readonly=True)
    push_count = fields.Integer(string="Subidas", default=0, readonly=True)
    pull_count = fields.Integer(string="Descargas", default=0, readonly=True)

    _sql_constraints = [
        ("posipv_sync_device_uuid_uniq", "unique(device_uuid)", "El UUID del dispositivo ya existe."),
    ]


class PosipvSyncLog(models.Model):
    _name = "posipv.sync.log"
    _description = "Bitácora de sincronización POSIPV"
    _order = "started_at desc, id desc"

    name = fields.Char(string="Descripción", required=True)
    device_id = fields.Many2one(
        "posipv.sync.device",
        string="Dispositivo",
        ondelete="set null",
    )
    direction = fields.Selection(
        [
            ("push", "Subida"),
            ("pull", "Descarga"),
            ("test", "Prueba"),
            ("register", "Registro"),
        ],
        string="Dirección",
        required=True,
    )
    endpoint = fields.Char(string="Endpoint", required=True)
    status = fields.Selection(
        [
            ("success", "Éxito"),
            ("failed", "Fallido"),
            ("warning", "Advertencia"),
        ],
        string="Estado",
        required=True,
    )
    started_at = fields.Datetime(string="Inicio", required=True)
    finished_at = fields.Datetime(string="Fin")
    request_count = fields.Integer(string="Solicitudes", default=0)
    record_count = fields.Integer(string="Registros", default=0)
    response_json = fields.Text(string="Respuesta JSON")
    error_message = fields.Text(string="Mensaje de error")


class PosipvSyncMirrorMixin(models.AbstractModel):
    _name = "posipv.sync.mirror.mixin"
    _description = "Campos comunes de espejo POSIPV"

    name = fields.Char(string="Nombre", required=True)
    external_uuid = fields.Char(string="UUID externo", required=True, index=True)
    device_id = fields.Many2one(
        "posipv.sync.device",
        string="Dispositivo origen",
        ondelete="set null",
    )
    source_updated_at = fields.Datetime(string="Actualizado en origen")
    received_at = fields.Datetime(
        string="Recibido en Odoo",
        default=fields.Datetime.now,
        readonly=True,
    )
    payload_json = fields.Text(string="Carga sincronizada (JSON)")
    active = fields.Boolean(string="Activo", default=True)
    company_id = fields.Many2one(
        "res.company",
        string="Compañía",
        default=lambda self: self.env.company.id,
    )


class PosipvCatalogProduct(models.Model):
    _name = "posipv.catalog.product"
    _description = "Producto espejo POSIPV"
    _inherit = "posipv.sync.mirror.mixin"
    _order = "name"

    product_id = fields.Many2one("product.product", string="Producto Odoo")
    sku = fields.Char(string="SKU", index=True)
    barcode = fields.Char(string="Código de barras", index=True)
    sale_price = fields.Float(string="Precio de venta", digits=(16, 2))
    cost_price = fields.Float(string="Precio de costo", digits=(16, 2))
    currency_code = fields.Char(string="Moneda", size=8)
    category_name = fields.Char(string="Categoría")
    product_type = fields.Char(string="Tipo de producto")
    unit_measure = fields.Char(string="Unidad de medida")
    order_costing_mode = fields.Char(string="Modo de costeo")

    _sql_constraints = [
        ("posipv_catalog_product_external_uuid_uniq", "unique(external_uuid)", "El UUID externo del producto ya existe."),
    ]


class PosipvCatalogCustomer(models.Model):
    _name = "posipv.catalog.customer"
    _description = "Cliente espejo POSIPV"
    _inherit = "posipv.sync.mirror.mixin"
    _order = "name"

    partner_id = fields.Many2one("res.partner", string="Contacto Odoo")
    code = fields.Char(string="Código", index=True)
    identity_number = fields.Char(string="Número de identidad")
    phone = fields.Char(string="Teléfono")
    email = fields.Char(string="Correo electrónico")
    address = fields.Char(string="Dirección")
    company_name = fields.Char(string="Empresa")
    customer_type = fields.Char(string="Tipo de cliente")
    is_vip = fields.Boolean(string="Cliente VIP", default=False)
    discount_bps = fields.Integer(string="Descuento (pbs)", default=0)

    _sql_constraints = [
        ("posipv_catalog_customer_external_uuid_uniq", "unique(external_uuid)", "El UUID externo del cliente ya existe."),
    ]


class PosipvCatalogEmployee(models.Model):
    _name = "posipv.catalog.employee"
    _description = "Empleado espejo POSIPV"
    _inherit = "posipv.sync.mirror.mixin"
    _order = "name"

    employee_id = fields.Many2one("hr.employee", string="Empleado Odoo")
    code = fields.Char(string="Código", index=True)
    identity_number = fields.Char(string="Número de identidad")
    sex = fields.Char(string="Sexo")
    associated_username = fields.Char(string="Usuario asociado")

    _sql_constraints = [
        ("posipv_catalog_employee_external_uuid_uniq", "unique(external_uuid)", "El UUID externo del empleado ya existe."),
    ]


class PosipvCatalogWarehouse(models.Model):
    _name = "posipv.catalog.warehouse"
    _description = "Almacén espejo POSIPV"
    _inherit = "posipv.sync.mirror.mixin"
    _order = "name"

    warehouse_id = fields.Many2one("stock.warehouse", string="Almacén Odoo")
    warehouse_type = fields.Char(string="Tipo de almacén")

    _sql_constraints = [
        ("posipv_catalog_warehouse_external_uuid_uniq", "unique(external_uuid)", "El UUID externo del almacén ya existe."),
    ]


class PosipvCatalogTerminal(models.Model):
    _name = "posipv.catalog.terminal"
    _description = "TPV espejo POSIPV"
    _inherit = "posipv.sync.mirror.mixin"
    _order = "name"

    pos_config_id = fields.Many2one("pos.config", string="TPV Odoo")
    code = fields.Char(string="Código", index=True)
    warehouse_external_uuid = fields.Char(string="UUID externo del almacén")
    currency_code = fields.Char(string="Moneda de operación", size=8)
    payment_methods_json = fields.Text(string="Métodos de pago (JSON)")

    _sql_constraints = [
        ("posipv_catalog_terminal_external_uuid_uniq", "unique(external_uuid)", "El UUID externo del TPV ya existe."),
    ]


class PosipvSale(models.Model):
    _name = "posipv.sale"
    _description = "Venta espejo POSIPV"
    _inherit = "posipv.sync.mirror.mixin"
    _order = "sale_datetime desc, id desc"

    folio = fields.Char(string="Folio", required=True, index=True)
    warehouse_name = fields.Char(string="Almacén")
    terminal_name = fields.Char(string="TPV")
    cashier_name = fields.Char(string="Cajero")
    customer_name = fields.Char(string="Cliente")
    subtotal_amount = fields.Float(string="Subtotal", digits=(16, 2))
    tax_amount = fields.Float(string="Impuesto", digits=(16, 2))
    total_amount = fields.Float(string="Total", digits=(16, 2))
    status = fields.Char(string="Estado")
    sale_datetime = fields.Datetime(string="Fecha de venta")
    line_ids = fields.One2many("posipv.sale.line", "sale_id", string="Líneas")
    payment_ids = fields.One2many("posipv.sale.payment", "sale_id", string="Pagos")

    _sql_constraints = [
        ("posipv_sale_external_uuid_uniq", "unique(external_uuid)", "El UUID externo de la venta ya existe."),
    ]


class PosipvSaleLine(models.Model):
    _name = "posipv.sale.line"
    _description = "Línea de venta espejo POSIPV"
    _order = "id"

    sale_id = fields.Many2one(
        "posipv.sale",
        string="Venta",
        required=True,
        ondelete="cascade",
    )
    external_uuid = fields.Char(string="UUID externo", index=True)
    product_name = fields.Char(string="Producto", required=True)
    product_sku = fields.Char(string="SKU")
    qty = fields.Float(string="Cantidad", digits=(16, 2))
    unit_price = fields.Float(string="Precio unitario", digits=(16, 2))
    unit_cost = fields.Float(string="Costo unitario", digits=(16, 2))
    tax_rate_bps = fields.Integer(string="Impuesto (pbs)", default=0)
    line_total = fields.Float(string="Importe", digits=(16, 2))
    payload_json = fields.Text(string="Carga sincronizada (JSON)")


class PosipvSalePayment(models.Model):
    _name = "posipv.sale.payment"
    _description = "Pago de venta espejo POSIPV"
    _order = "payment_datetime asc, id asc"

    sale_id = fields.Many2one(
        "posipv.sale",
        string="Venta",
        required=True,
        ondelete="cascade",
    )
    external_uuid = fields.Char(string="UUID externo", index=True)
    method = fields.Char(string="Método de pago", required=True)
    amount = fields.Float(string="Monto equivalente", digits=(16, 2))
    transaction_id = fields.Char(string="ID de transacción")
    source_currency_code = fields.Char(string="Moneda ingresada", size=8)
    source_amount = fields.Float(string="Monto ingresado", digits=(16, 2))
    payment_datetime = fields.Datetime(string="Fecha de pago")
    payload_json = fields.Text(string="Carga sincronizada (JSON)")


class PosipvStockMovement(models.Model):
    _name = "posipv.stock.movement"
    _description = "Movimiento de inventario espejo POSIPV"
    _inherit = "posipv.sync.mirror.mixin"
    _order = "movement_datetime desc, id desc"

    product_name = fields.Char(string="Producto")
    product_sku = fields.Char(string="SKU")
    warehouse_name = fields.Char(string="Almacén")
    movement_type = fields.Char(string="Tipo de movimiento")
    qty = fields.Float(string="Cantidad", digits=(16, 2))
    reason_code = fields.Char(string="Motivo")
    movement_source = fields.Char(string="Origen")
    ref_type = fields.Char(string="Tipo de referencia")
    ref_id = fields.Char(string="ID de referencia", index=True)
    is_voided = fields.Boolean(string="Anulado", default=False)
    created_by_name = fields.Char(string="Registrado por")
    movement_datetime = fields.Datetime(string="Fecha del movimiento")

    _sql_constraints = [
        ("posipv_stock_move_external_uuid_uniq", "unique(external_uuid)", "El UUID externo del movimiento ya existe."),
    ]


class PosipvWorkOrder(models.Model):
    _name = "posipv.work.order"
    _description = "Pedido espejo POSIPV"
    _inherit = "posipv.sync.mirror.mixin"
    _order = "source_created_at desc, id desc"

    folio = fields.Char(string="Folio", required=True, index=True)
    customer_name = fields.Char(string="Cliente")
    title = fields.Char(string="Título", required=True)
    description = fields.Text(string="Descripción")
    status = fields.Char(string="Estado técnico")
    payment_status = fields.Char(string="Estado de cobro técnico")
    priority = fields.Char(string="Prioridad técnica")
    work_type = fields.Char(string="Tipo de trabajo")
    assigned_employee_name = fields.Char(string="Responsable principal")
    qty = fields.Float(string="Cantidad", digits=(16, 2))
    unit_label = fields.Char(string="Unidad")
    due_at = fields.Datetime(string="Entrega estimada")
    source_created_at = fields.Datetime(string="Creado en la app")
    source_updated_at = fields.Datetime(string="Última edición en la app")
    completed_at = fields.Datetime(string="Producción finalizada")
    delivered_at = fields.Datetime(string="Entregado")
    paid_at = fields.Datetime(string="Cobrado")
    note = fields.Text(string="Observaciones")
    items_json = fields.Text(string="Productos solicitados (JSON)")
    assignments_json = fields.Text(string="Responsables asignados (JSON)")
    quoted_totals_json = fields.Text(string="Totales cotizados (JSON)")
    quoted_requested_lines_json = fields.Text(
        string="Líneas cotizadas del pedido (JSON)"
    )
    quoted_payment_variants_json = fields.Text(
        string="Variantes de cobro cotizadas (JSON)"
    )
    pricing_snapshot_json = fields.Text(string="Tasa y reglas congeladas (JSON)")
    payment_lines_json = fields.Text(string="Pagos registrados (JSON)")
    task_ids = fields.One2many("posipv.work.order.task", "order_id", string="Trabajos")
    requested_items_count = fields.Integer(
        string="Productos solicitados",
        compute="_compute_work_order_metrics",
        store=True,
    )
    assigned_team_count = fields.Integer(
        string="Responsables",
        compute="_compute_work_order_metrics",
        store=True,
    )
    task_count = fields.Integer(
        string="Trabajos realizados",
        compute="_compute_work_order_metrics",
        store=True,
    )
    material_line_count = fields.Integer(
        string="Líneas de materiales",
        compute="_compute_work_order_metrics",
        store=True,
    )
    waste_line_count = fields.Integer(
        string="Líneas de merma",
        compute="_compute_work_order_metrics",
        store=True,
    )
    worker_assignment_count = fields.Integer(
        string="Participaciones de trabajadores",
        compute="_compute_work_order_metrics",
        store=True,
    )
    payment_line_count = fields.Integer(
        string="Líneas de pago",
        compute="_compute_work_order_metrics",
        store=True,
    )
    quoted_amount_usd = fields.Float(
        string="Cotizado USD",
        digits=(16, 2),
        compute="_compute_work_order_metrics",
        store=True,
    )
    quoted_amount_cup_cash = fields.Float(
        string="Cotizado CUP efectivo",
        digits=(16, 2),
        compute="_compute_work_order_metrics",
        store=True,
    )
    quoted_amount_cup_transfer = fields.Float(
        string="Cotizado CUP transferencia",
        digits=(16, 2),
        compute="_compute_work_order_metrics",
        store=True,
    )
    quoted_amount_cup_other = fields.Float(
        string="Cotizado CUP otros",
        digits=(16, 2),
        compute="_compute_work_order_metrics",
        store=True,
    )
    is_overdue = fields.Boolean(
        string="Vencido",
        compute="_compute_is_overdue",
        search="_search_is_overdue",
    )
    status_label = fields.Char(
        string="Estado",
        compute="_compute_work_order_labels",
    )
    payment_status_label = fields.Char(
        string="Cobro",
        compute="_compute_work_order_labels",
    )
    priority_label = fields.Char(
        string="Prioridad",
        compute="_compute_work_order_labels",
    )

    _sql_constraints = [
        ("posipv_work_order_external_uuid_uniq", "unique(external_uuid)", "El UUID externo del pedido ya existe."),
    ]

    @api.depends(
        "items_json",
        "assignments_json",
        "quoted_payment_variants_json",
        "payment_lines_json",
        "task_ids",
        "task_ids.materials_json",
        "task_ids.waste_materials_json",
        "task_ids.workers_json",
    )
    def _compute_work_order_metrics(self):
        for record in self:
            items = record._json_list(record.items_json)
            assignments = record._json_list(record.assignments_json)
            variants = record._json_list(record.quoted_payment_variants_json)
            payment_lines = record._json_list(record.payment_lines_json)
            material_line_count = 0
            waste_line_count = 0
            worker_assignment_count = 0
            for task in record.task_ids:
                material_line_count += len(record._json_list(task.materials_json))
                waste_line_count += len(record._json_list(task.waste_materials_json))
                worker_assignment_count += len(record._json_list(task.workers_json))

            quoted_amount_usd = 0.0
            quoted_amount_cup_cash = 0.0
            quoted_amount_cup_transfer = 0.0
            quoted_amount_cup_other = 0.0
            for variant in variants:
                currency_code = str(variant.get("currencyCode") or "").strip().upper()
                label = str(variant.get("label") or "").strip().lower()
                amount = record._to_float(variant.get("amountCents")) / 100.0
                if currency_code == "USD":
                    quoted_amount_usd = amount
                elif currency_code == "CUP":
                    if "transfer" in label:
                        quoted_amount_cup_transfer = amount
                    elif "efectivo" in label:
                        quoted_amount_cup_cash = amount
                    else:
                        quoted_amount_cup_other += amount

            record.requested_items_count = len(items)
            record.assigned_team_count = len(assignments)
            record.task_count = len(record.task_ids)
            record.material_line_count = material_line_count
            record.waste_line_count = waste_line_count
            record.worker_assignment_count = worker_assignment_count
            record.payment_line_count = len(payment_lines)
            record.quoted_amount_usd = quoted_amount_usd
            record.quoted_amount_cup_cash = quoted_amount_cup_cash
            record.quoted_amount_cup_transfer = quoted_amount_cup_transfer
            record.quoted_amount_cup_other = quoted_amount_cup_other

    @api.depends("due_at", "status")
    def _compute_is_overdue(self):
        now = fields.Datetime.now()
        for record in self:
            record.is_overdue = bool(
                record.due_at
                and record.due_at < now
                and record.status not in ("delivered", "cancelled", "deleted")
            )

    @api.depends("status", "payment_status", "priority")
    def _compute_work_order_labels(self):
        status_labels = {
            "pending": "Pendiente",
            "in_progress": "En producción",
            "ready": "Pendiente a entregar",
            "delivered": "Finalizado",
            "cancelled": "Cancelado",
            "deleted": "Eliminado",
        }
        payment_labels = {
            "unpaid": "Pendiente de cobro",
            "partial": "Parcialmente pagado",
            "paid": "Cobrado",
        }
        priority_labels = {
            "low": "Baja",
            "normal": "Normal",
            "urgent": "Urgente",
        }
        for record in self:
            record.status_label = status_labels.get(record.status, record.status or "-")
            record.payment_status_label = payment_labels.get(
                record.payment_status, record.payment_status or "-"
            )
            record.priority_label = priority_labels.get(
                record.priority, record.priority or "-"
            )

    def _search_is_overdue(self, operator, value):
        expected = bool(value)
        overdue_domain = [
            ("due_at", "!=", False),
            ("due_at", "<", fields.Datetime.now()),
            ("status", "not in", ["delivered", "cancelled", "deleted"]),
        ]
        if (operator in ("=", "==") and expected) or (operator == "!=" and not expected):
            return overdue_domain
        return ["!"] + overdue_domain

    def _json_list(self, payload):
        if not payload:
            return []
        try:
            data = json.loads(payload)
        except Exception:
            return []
        return data if isinstance(data, list) else []

    def _to_float(self, value):
        try:
            return float(value or 0.0)
        except Exception:
            return 0.0


class PosipvWorkOrderTask(models.Model):
    _name = "posipv.work.order.task"
    _description = "Trabajo realizado espejo POSIPV"
    _order = "created_at asc, id asc"

    order_id = fields.Many2one(
        "posipv.work.order",
        string="Pedido",
        required=True,
        ondelete="cascade",
    )
    external_uuid = fields.Char(string="UUID externo", index=True)
    title = fields.Char(string="Tipo de trabajo", required=True)
    description = fields.Text(string="Descripción")
    materials_json = fields.Text(string="Materiales usados (JSON)")
    waste_materials_json = fields.Text(string="Merma registrada (JSON)")
    workers_json = fields.Text(string="Trabajadores participantes (JSON)")
    image_paths_json = fields.Text(string="Imágenes del trabajo (JSON)")
    created_at = fields.Datetime(string="Fecha del trabajo")
    payload_json = fields.Text(string="Carga sincronizada (JSON)")
