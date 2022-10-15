# Docker workflow with deps

Containerize a Shiny app.

Use the Dockerfile in this folder if you already have
the `dependencies.json` file from `deps::create()`:

```bash
cd inst/examples/02-docker

# change this as needed if you want to `docker push`
export TAG=analythium/deps-shiny-example:v1

docker build -t $TAG .

docker run -p 8080:8080 $TAG
```

If you don't have the `dependencies.json` file, you can use this Dockerfile
(remember: this version is not optimized for caching the image layers):

```Dockerfile
FROM eddelbuettel/r2u:22.04

RUN installGithub.r analythium/deps
RUN apt-get update && apt-get install -y --no-install-recommends jq

RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /home/app
COPY app .

RUN R -q -e "deps::create()"
RUN apt-get install -y --no-install-recommends \
    $( jq -r '.sysreqs | join(" ")' dependencies.json )
RUN R -q -e "deps::install()"

RUN chown app:app -R /home/app
USER app

EXPOSE 8080
CMD ["R", "-e", "shiny::runApp(port = 8080, host = '0.0.0.0')"]
```
