from prometheus_client import Counter, Histogram, generate_latest
from flask import request, g
import time


REQUEST_COUNT = Counter(
    "task_manager_http_requests_total",
    "Total number of HTTP requests",
    ["method", "endpoint", "status"]
)

REQUEST_LATENCY = Histogram(
    "task_manager_http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "endpoint"]
)


def register_metrics(app):

    @app.before_request
    def start_timer():
        g.start_time = time.perf_counter()

    @app.after_request
    def record_metrics(response):
        start_time = getattr(g, "start_time", None)

        if start_time is None:
            duration = 0.0
        else:
            duration = time.perf_counter() - start_time

        endpoint = request.endpoint or "unknown"

        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=endpoint,
            status=response.status_code
        ).inc()

        REQUEST_LATENCY.labels(
            method=request.method,
            endpoint=endpoint
        ).observe(duration)

        return response

    @app.route("/metrics")
    def metrics():
        return generate_latest(), 200, {
            "Content-Type": "text/plain; version=0.0.4; charset=utf-8"
        }
