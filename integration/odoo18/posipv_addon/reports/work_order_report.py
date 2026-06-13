import json

from odoo import api, models


class PosipvWorkOrderDetailReport(models.AbstractModel):
    _name = "report.posipv.report_work_orders_detail"
    _description = "Reporte detallado de pedidos POSIPV"

    def _json_list(self, payload):
        if not payload:
            return []
        try:
            data = json.loads(payload)
        except Exception:
            return []
        return data if isinstance(data, list) else []

    def _json_dict(self, payload):
        if not payload:
            return {}
        try:
            data = json.loads(payload)
        except Exception:
            return {}
        return data if isinstance(data, dict) else {}

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

    @api.model
    def _get_report_values(self, docids, data=None):
        docs = self.env["posipv.work.order"].sudo().browse(docids)
        orders = []
        for order in docs:
            tasks = []
            for task in order.task_ids:
                tasks.append(
                    {
                        "title": task.title,
                        "description": task.description,
                        "created_at": task.created_at,
                        "materials": self._json_list(task.materials_json),
                        "waste_materials": self._json_list(task.waste_materials_json),
                        "workers": self._json_list(task.workers_json),
                        "image_paths": self._json_list(task.image_paths_json),
                    }
                )
            quoted_payment_variants = []
            for variant in self._json_list(order.quoted_payment_variants_json):
                quoted_payment_variants.append(
                    {
                        "label": variant.get("label") or "-",
                        "currency_code": variant.get("currencyCode") or "-",
                        "amount": self._amount_from_cents(
                            variant.get("amountCents")
                        ),
                    }
                )
            payment_lines = []
            for payment in self._json_list(order.payment_lines_json):
                payment_lines.append(
                    {
                        "method_label": payment.get("methodLabel")
                        or payment.get("methodCode")
                        or "-",
                        "currency_code": payment.get("currencyCode") or "-",
                        "amount": self._amount_from_cents(
                            payment.get("enteredAmountCents")
                        ),
                        "primary_currency_code": payment.get("primaryCurrencyCode")
                        or payment.get("currencyCode")
                        or "-",
                        "equivalent_amount": self._amount_from_cents(
                            payment.get("equivalentAmountCents")
                            or payment.get("enteredAmountCents")
                        ),
                        "applied_rate_to_primary": payment.get("appliedRateToPrimary")
                        or 1,
                        "quote_label": payment.get("quoteLabel") or "",
                        "paid_at": payment.get("paidAt") or "-",
                        "transaction_id": payment.get("transactionId") or "",
                    }
                )
            orders.append(
                {
                    "record": order,
                    "status_label": self._status_label(order.status),
                    "payment_label": self._payment_label(order.payment_status),
                    "priority_label": self._priority_label(order.priority),
                    "items": self._json_list(order.items_json),
                    "assignments": self._json_list(order.assignments_json),
                    "quoted_totals": self._json_list(order.quoted_totals_json),
                    "quoted_requested_lines": self._json_list(order.quoted_requested_lines_json),
                    "quoted_payment_variants": quoted_payment_variants,
                    "pricing_snapshot": self._json_dict(order.pricing_snapshot_json),
                    "payment_lines": payment_lines,
                    "tasks": tasks,
                }
            )
        return {
            "doc_ids": docs.ids,
            "doc_model": "posipv.work.order",
            "docs": docs,
            "orders": orders,
        }
