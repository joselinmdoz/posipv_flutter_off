import json

from odoo import api, models


class PosipvWorkOrderDashboardReportMixin(models.AbstractModel):
    _name = "report.posipv.work_order_dashboard_report_mixin"
    _description = "Herramientas para reportes del panel POSIPV"

    def _json_list(self, payload):
        if not payload:
            return []
        try:
            data = json.loads(payload)
        except Exception:
            return []
        return data if isinstance(data, list) else []

    def _status_label(self, value):
        return {
            "pending": "Pendiente",
            "in_progress": "En producción",
            "ready": "Pendiente a entregar",
            "delivered": "Finalizado",
            "cancelled": "Cancelado",
            "deleted": "Eliminado",
        }.get(value, value or "-")

    def _payment_label(self, value):
        return {
            "unpaid": "Pendiente de cobro",
            "partial": "Parcialmente pagado",
            "paid": "Cobrado",
        }.get(value, value or "-")

    def _priority_label(self, value):
        return {
            "low": "Baja",
            "normal": "Normal",
            "urgent": "Urgente",
        }.get(value, value or "-")

    def _amount_from_cents(self, value):
        try:
            return float(value or 0.0) / 100.0
        except Exception:
            return 0.0

    def _dashboard_payload(self, wizard):
        orders = wizard._filtered_orders()
        return {
            "wizard": wizard,
            "orders": orders,
            "filter_summary": wizard._filter_summary(),
        }


class PosipvWorkOrderFilteredReport(models.AbstractModel):
    _name = "report.posipv.report_work_orders_filtered"
    _inherit = "report.posipv.work_order_dashboard_report_mixin"
    _description = "Reporte filtrado de pedidos POSIPV"

    @api.model
    def _get_report_values(self, docids, data=None):
        wizards = self.env["posipv.work.order.dashboard"].sudo().browse(docids)
        docs = []
        for wizard in wizards:
            payload = self._dashboard_payload(wizard)
            order_rows = []
            for order in payload["orders"]:
                task_rows = []
                for task in order.task_ids:
                    task_rows.append(
                        {
                            "title": task.title,
                            "description": task.description,
                            "created_at": task.created_at,
                            "materials": self._json_list(task.materials_json),
                            "waste_materials": self._json_list(task.waste_materials_json),
                            "workers": self._json_list(task.workers_json),
                        }
                    )
                payment_rows = []
                for payment in self._json_list(order.payment_lines_json):
                    payment_rows.append(
                        {
                            "method_label": payment.get("methodLabel")
                            or payment.get("methodCode")
                            or "-",
                            "currency_code": payment.get("currencyCode") or "-",
                            "amount": self._amount_from_cents(
                                payment.get("enteredAmountCents")
                            ),
                            "quote_label": payment.get("quoteLabel") or "",
                            "paid_at": payment.get("paidAt") or "-",
                            "transaction_id": payment.get("transactionId") or "",
                        }
                    )
                order_rows.append(
                    {
                        "record": order,
                        "status_label": self._status_label(order.status),
                        "payment_label": self._payment_label(order.payment_status),
                        "priority_label": self._priority_label(order.priority),
                        "items": self._json_list(order.items_json),
                        "assignments": self._json_list(order.assignments_json),
                        "payment_variants": self._json_list(
                            order.quoted_payment_variants_json
                        ),
                        "payments": payment_rows,
                        "tasks": task_rows,
                    }
                )
            docs.append(
                {
                    "wizard": wizard,
                    "orders": order_rows,
                    "filter_summary": payload["filter_summary"],
                }
            )
        return {
            "doc_ids": wizards.ids,
            "doc_model": "posipv.work.order.dashboard",
            "docs": wizards,
            "dashboards": docs,
        }


class PosipvWorkOrderMaterialsReport(models.AbstractModel):
    _name = "report.posipv.report_work_orders_materials"
    _inherit = "report.posipv.work_order_dashboard_report_mixin"
    _description = "Reporte de materiales y merma POSIPV"

    @api.model
    def _get_report_values(self, docids, data=None):
        wizards = self.env["posipv.work.order.dashboard"].sudo().browse(docids)
        docs = []
        for wizard in wizards:
            payload = self._dashboard_payload(wizard)
            order_rows = []
            for order in payload["orders"]:
                tasks = []
                material_count = 0
                waste_count = 0
                for task in order.task_ids:
                    materials = self._json_list(task.materials_json)
                    waste = self._json_list(task.waste_materials_json)
                    material_count += len(materials)
                    waste_count += len(waste)
                    tasks.append(
                        {
                            "title": task.title,
                            "description": task.description,
                            "created_at": task.created_at,
                            "materials": materials,
                            "waste_materials": waste,
                            "workers": self._json_list(task.workers_json),
                        }
                    )
                order_rows.append(
                    {
                        "record": order,
                        "status_label": self._status_label(order.status),
                        "tasks": tasks,
                        "material_count": material_count,
                        "waste_count": waste_count,
                    }
                )
            docs.append(
                {
                    "wizard": wizard,
                    "orders": order_rows,
                    "filter_summary": payload["filter_summary"],
                }
            )
        return {
            "doc_ids": wizards.ids,
            "doc_model": "posipv.work.order.dashboard",
            "docs": wizards,
            "dashboards": docs,
        }
