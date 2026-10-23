# Zipkin Distributed Tracing

Zipkin is the trace collector and UI for the Ecomera platform. Spring services ship spans to it via
Micrometer Tracing (Brave + Zipkin reporter), and Zipkin stitches those spans back into complete
request traces across the API Gateway, service-to-service (Feign) calls and Kafka.

## Start

```bash
docker compose up -d zipkin
```

## Access the UI

Open <http://localhost:9411>.

Services running on the host send spans to `http://localhost:9411/api/v2/spans`
(`ZIPKIN_URL` in `.env`). Services running **inside** the compose network must use
`http://zipkin:9411/api/v2/spans` instead.

## Trace vs span

- **Trace** one request, end to end, identified by a single `traceId`.
- **Span** one unit of work inside that request (an HTTP call, a DB query, a Kafka publish),
  identified by a `spanId` and linked to its caller via `parentSpanId`.
- A trace is a tree of spans. The span at the root is the entry point (usually the Gateway).

## Reading a trace in the UI

1. Pick a service (e.g. `ecomera-api-gateway`) and hit **Run Query**.
2. Open a trace to see the **timeline**: each bar is a span, nested by parent/child.
3. Look for the **longest bar** that is where the request spent most of its time.
4. Click a span to inspect its tags (`http.method`, `http.path`, `http.status_code`, errors).
5. Use **Dependencies** to see which services call which under real traffic.

## Storage

By default Zipkin keeps traces **in memory**; they are lost when the container restarts. That is
intentional for local development. Persisting traces would require a supported backend
(Elasticsearch, Cassandra or MySQL) out of scope for this sprint.

## Troubleshooting

| Symptom | Check |
|---|---|
| No traces in the UI | Is `zipkin` healthy? `docker compose ps zipkin` |
| Service missing from the service dropdown | Does the service have the tracing deps and `management.zipkin.tracing.endpoint` set? |
| Traces stop at a service boundary | Is `management.tracing.sampling.probability` > 0 and B3 propagation enabled? |
| Wrong endpoint | Host-run services use `localhost:9411`; in-network services use `zipkin:9411` |
