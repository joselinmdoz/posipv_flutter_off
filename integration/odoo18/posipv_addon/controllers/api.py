import json

from odoo import SUPERUSER_ID, api, http
from odoo.exceptions import UserError
from odoo.http import request
from odoo.modules.registry import Registry


class PosipvApiController(http.Controller):
    def _read_payload(self):
        return request.httprequest.get_json(silent=True) or {}

    def _resolve_db_name(self, payload):
        session_db = getattr(getattr(request, "session", None), "db", None)
        return (
            request.httprequest.args.get("db")
            or payload.get("db")
            or session_db
        )

    def _json_response(self, payload, status=200):
        return request.make_response(
            json.dumps(payload, ensure_ascii=False, default=str),
            headers=[("Content-Type", "application/json")],
            status=status,
        )

    def _handle(self, payload, callback):
        cr = None
        try:
            db_name = self._resolve_db_name(payload)
            if not db_name:
                raise UserError("Debes indicar la base de datos de Odoo.")
            registry = Registry(db_name)
            cr = registry.cursor()
            env = api.Environment(cr, SUPERUSER_ID, {})
            response = callback(env["posipv.sync.service"].sudo())
            cr.commit()
            return self._json_response(response)
        except UserError as exc:
            return self._json_response(
                {
                    "ok": False,
                    "message": str(exc),
                },
                status=400,
            )
        except Exception as exc:
            return self._json_response(
                {
                    "ok": False,
                    "message": "Error interno del backend POSIPV.",
                    "details": str(exc),
                },
                status=500,
            )
        finally:
            if cr is not None:
                cr.close()

    @http.route(
        "/posipv/api/v1/ping",
        type="http",
        auth="none",
        methods=["POST"],
        csrf=False,
    )
    def ping(self, **kwargs):
        payload = self._read_payload()
        return self._handle(payload, lambda service: service.ping())

    @http.route(
        "/posipv/api/v1/device/register",
        type="http",
        auth="none",
        methods=["POST"],
        csrf=False,
    )
    def register_device(self, **kwargs):
        payload = self._read_payload()
        return self._handle(
            payload, lambda service: service.register_device(payload)
        )

    @http.route(
        "/posipv/api/v1/pull/master-data",
        type="http",
        auth="none",
        methods=["POST"],
        csrf=False,
    )
    def pull_master_data(self, **kwargs):
        payload = self._read_payload()
        device_uuid = request.httprequest.headers.get("X-POSIPV-Device") or payload.get(
            "device_uuid"
        )
        api_key = request.httprequest.headers.get("X-POSIPV-Key") or payload.get(
            "api_key"
        )
        return self._handle(
            payload,
            lambda service: service.export_master_data(device_uuid, api_key),
        )

    @http.route(
        "/posipv/api/v1/pull/work-orders",
        type="http",
        auth="none",
        methods=["POST"],
        csrf=False,
    )
    def pull_work_orders(self, **kwargs):
        payload = self._read_payload()
        device_uuid = request.httprequest.headers.get("X-POSIPV-Device") or payload.get(
            "device_uuid"
        )
        api_key = request.httprequest.headers.get("X-POSIPV-Key") or payload.get(
            "api_key"
        )
        return self._handle(
            payload,
            lambda service: service.export_work_orders(device_uuid, api_key),
        )

    @http.route(
        "/posipv/api/v1/push/batch",
        type="http",
        auth="none",
        methods=["POST"],
        csrf=False,
    )
    def push_batch(self, **kwargs):
        payload = self._read_payload()
        device_uuid = request.httprequest.headers.get("X-POSIPV-Device") or payload.get(
            "device_uuid"
        )
        api_key = request.httprequest.headers.get("X-POSIPV-Key") or payload.get(
            "api_key"
        )
        return self._handle(
            payload,
            lambda service: service.receive_batch(device_uuid, api_key, payload),
        )
