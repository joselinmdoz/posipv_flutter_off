{
    "name": "Centro de Sincronización POSIPV",
    "version": "18.0.1.0.0",
    "category": "Operaciones",
    "summary": "Servidor espejo para la app offline POSIPV",
    "description": """
Centro de Sincronización POSIPV
===============================

Servidor administrativo y de sincronización para la app POSIPV.

- Registra dispositivos autorizados
- Recibe ventas, pagos, movimientos y pedidos desde la app
- Expone catálogos maestros para la sincronización offline-first
- Mantiene los datos en modelos propios sin tocar todavía la lógica nativa de Odoo
    """,
    "author": "OpenAI / Codex",
    "license": "LGPL-3",
    "application": True,
    "installable": True,
    "depends": [
        "base",
        "contacts",
        "product",
        "hr",
        "stock",
        "point_of_sale",
    ],
    "data": [
        "security/posipv_security.xml",
        "security/ir.model.access.csv",
        "views/root_menu.xml",
        "views/settings_views.xml",
        "views/device_views.xml",
        "views/catalog_views.xml",
        "views/work_order_dashboard_views.xml",
        "reports/work_order_report.xml",
        "reports/work_order_dashboard_reports.xml",
        "views/transaction_views.xml",
    ],
}
