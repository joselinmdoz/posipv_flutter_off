import json
from datetime import timedelta

from odoo import api, fields, models


class PosipvWorkOrderDashboard(models.TransientModel):
    _name = "posipv.work.order.dashboard"
    _description = "Panel informativo de pedidos POSIPV"

    name = fields.Char(default="Panel de pedidos")
    date_basis = fields.Selection(
        [
            ("source_created_at", "Fecha del pedido"),
            ("due_at", "Fecha de entrega"),
            ("completed_at", "Producción finalizada"),
            ("delivered_at", "Fecha de entrega real"),
            ("paid_at", "Fecha de cobro"),
        ],
        string="Base del rango",
        default="source_created_at",
        required=True,
    )
    date_from = fields.Date(string="Desde")
    date_to = fields.Date(string="Hasta")
    search_text = fields.Char(string="Búsqueda general")
    status = fields.Selection(
        [
            ("", "Todos"),
            ("pending", "Pendiente"),
            ("in_progress", "En producción"),
            ("ready", "Pendiente a entregar"),
            ("delivered", "Finalizado"),
            ("cancelled", "Cancelado"),
            ("deleted", "Eliminado"),
        ],
        string="Estado",
        default="",
    )
    payment_status = fields.Selection(
        [
            ("", "Todos"),
            ("unpaid", "Pendiente de cobro"),
            ("partial", "Parcialmente pagado"),
            ("paid", "Cobrado"),
        ],
        string="Cobro",
        default="",
    )
    priority = fields.Selection(
        [
            ("", "Todas"),
            ("low", "Baja"),
            ("normal", "Normal"),
            ("urgent", "Urgente"),
        ],
        string="Prioridad",
        default="",
    )
    device_id = fields.Many2one("posipv.sync.device", string="Dispositivo")
    customer_name = fields.Char(string="Cliente")
    assigned_employee_name = fields.Char(string="Responsable")
    overdue_only = fields.Boolean(string="Solo vencidos")
    with_tasks_only = fields.Boolean(string="Solo con trabajos")
    with_payments_only = fields.Boolean(string="Solo con pagos")

    total_orders = fields.Integer(
        string="Pedidos",
        compute="_compute_metrics",
    )
    total_pending = fields.Integer(
        string="Pendientes",
        compute="_compute_metrics",
    )
    total_in_progress = fields.Integer(
        string="En producción",
        compute="_compute_metrics",
    )
    total_ready = fields.Integer(
        string="Pendientes a entregar",
        compute="_compute_metrics",
    )
    total_delivered = fields.Integer(
        string="Finalizados",
        compute="_compute_metrics",
    )
    total_cancelled = fields.Integer(
        string="Cancelados",
        compute="_compute_metrics",
    )
    total_unpaid = fields.Integer(
        string="Pendientes de cobro",
        compute="_compute_metrics",
    )
    total_partial = fields.Integer(
        string="Parcialmente pagados",
        compute="_compute_metrics",
    )
    total_paid = fields.Integer(
        string="Cobrados",
        compute="_compute_metrics",
    )
    total_tasks = fields.Integer(
        string="Trabajos realizados",
        compute="_compute_metrics",
    )
    total_material_lines = fields.Integer(
        string="Líneas de materiales",
        compute="_compute_metrics",
    )
    total_waste_lines = fields.Integer(
        string="Líneas de merma",
        compute="_compute_metrics",
    )
    total_payment_lines = fields.Integer(
        string="Líneas de pago",
        compute="_compute_metrics",
    )
    quoted_amount_usd = fields.Float(
        string="Cotizado USD",
        digits=(16, 2),
        compute="_compute_metrics",
    )
    quoted_amount_cup_cash = fields.Float(
        string="Cotizado CUP efectivo",
        digits=(16, 2),
        compute="_compute_metrics",
    )
    quoted_amount_cup_transfer = fields.Float(
        string="Cotizado CUP transferencia",
        digits=(16, 2),
        compute="_compute_metrics",
    )

    def _build_domain(self):
        self.ensure_one()
        domain = []
        if self.status:
            domain.append(("status", "=", self.status))
        if self.payment_status:
            domain.append(("payment_status", "=", self.payment_status))
        if self.priority:
            domain.append(("priority", "=", self.priority))
        if self.device_id:
            domain.append(("device_id", "=", self.device_id.id))
        if self.customer_name:
            domain.append(("customer_name", "ilike", self.customer_name.strip()))
        if self.assigned_employee_name:
            domain.append(
                ("assigned_employee_name", "ilike", self.assigned_employee_name.strip())
            )
        if self.search_text:
            search = self.search_text.strip()
            domain += [
                "|",
                "|",
                "|",
                "|",
                ("folio", "ilike", search),
                ("title", "ilike", search),
                ("customer_name", "ilike", search),
                ("assigned_employee_name", "ilike", search),
                ("description", "ilike", search),
            ]
        if self.overdue_only:
            domain.append(("is_overdue", "=", True))
        if self.with_tasks_only:
            domain.append(("task_count", ">", 0))
        if self.with_payments_only:
            domain.append(("payment_line_count", ">", 0))

        if self.date_from:
            domain.append((self.date_basis, ">=", fields.Datetime.to_datetime(self.date_from)))
        if self.date_to:
            end_dt = fields.Datetime.to_datetime(self.date_to) + timedelta(days=1)
            domain.append((self.date_basis, "<", end_dt))
        return domain

    def _filtered_orders(self):
        self.ensure_one()
        return self.env["posipv.work.order"].sudo().search(
            self._build_domain(),
            order="source_created_at desc, id desc",
        )

    @api.depends(
        "date_basis",
        "date_from",
        "date_to",
        "search_text",
        "status",
        "payment_status",
        "priority",
        "device_id",
        "customer_name",
        "assigned_employee_name",
        "overdue_only",
        "with_tasks_only",
        "with_payments_only",
    )
    def _compute_metrics(self):
        for wizard in self:
            orders = wizard._filtered_orders()
            wizard.total_orders = len(orders)
            wizard.total_pending = len(orders.filtered(lambda x: x.status == "pending"))
            wizard.total_in_progress = len(
                orders.filtered(lambda x: x.status == "in_progress")
            )
            wizard.total_ready = len(orders.filtered(lambda x: x.status == "ready"))
            wizard.total_delivered = len(
                orders.filtered(lambda x: x.status == "delivered")
            )
            wizard.total_cancelled = len(
                orders.filtered(lambda x: x.status in ("cancelled", "deleted"))
            )
            wizard.total_unpaid = len(
                orders.filtered(lambda x: x.payment_status == "unpaid")
            )
            wizard.total_partial = len(
                orders.filtered(lambda x: x.payment_status == "partial")
            )
            wizard.total_paid = len(orders.filtered(lambda x: x.payment_status == "paid"))
            wizard.total_tasks = sum(orders.mapped("task_count"))
            wizard.total_material_lines = sum(orders.mapped("material_line_count"))
            wizard.total_waste_lines = sum(orders.mapped("waste_line_count"))
            wizard.total_payment_lines = sum(orders.mapped("payment_line_count"))
            wizard.quoted_amount_usd = sum(orders.mapped("quoted_amount_usd"))
            wizard.quoted_amount_cup_cash = sum(orders.mapped("quoted_amount_cup_cash"))
            wizard.quoted_amount_cup_transfer = sum(
                orders.mapped("quoted_amount_cup_transfer")
            )

    def action_view_orders(self):
        self.ensure_one()
        action = self.env.ref("posipv.action_posipv_work_order").read()[0]
        action["domain"] = self._build_domain()
        action["context"] = {
            "search_default_group_status": 1,
        }
        return action

    def action_clear_filters(self):
        self.write(
            {
                "date_basis": "source_created_at",
                "date_from": False,
                "date_to": False,
                "search_text": False,
                "status": "",
                "payment_status": "",
                "priority": "",
                "device_id": False,
                "customer_name": False,
                "assigned_employee_name": False,
                "overdue_only": False,
                "with_tasks_only": False,
                "with_payments_only": False,
            }
        )
        return {
            "type": "ir.actions.act_window",
            "res_model": "posipv.work.order.dashboard",
            "view_mode": "form",
            "res_id": self.id,
            "target": "current",
        }

    def action_print_orders_report(self):
        self.ensure_one()
        return self.env.ref("posipv.action_report_posipv_work_order_filtered").report_action(
            self
        )

    def action_print_materials_report(self):
        self.ensure_one()
        return self.env.ref(
            "posipv.action_report_posipv_work_order_materials"
        ).report_action(self)

    def _filter_summary(self):
        self.ensure_one()
        return {
            "base_rango": dict(self._fields["date_basis"].selection).get(self.date_basis),
            "desde": self.date_from,
            "hasta": self.date_to,
            "busqueda": self.search_text or "Sin búsqueda",
            "estado": dict(self._fields["status"].selection).get(self.status) or "Todos",
            "cobro": dict(self._fields["payment_status"].selection).get(self.payment_status)
            or "Todos",
            "prioridad": dict(self._fields["priority"].selection).get(self.priority)
            or "Todas",
            "dispositivo": self.device_id.name or "Todos",
            "cliente": self.customer_name or "Todos",
            "responsable": self.assigned_employee_name or "Todos",
            "solo_vencidos": "Sí" if self.overdue_only else "No",
            "solo_con_trabajos": "Sí" if self.with_tasks_only else "No",
            "solo_con_pagos": "Sí" if self.with_payments_only else "No",
        }

    def _safe_json_list(self, payload):
        if not payload:
            return []
        try:
            data = json.loads(payload)
        except Exception:
            return []
        return data if isinstance(data, list) else []
