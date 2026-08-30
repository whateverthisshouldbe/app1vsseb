# Voedingsschema App

Standalone HTML-app (alles gebundeld in `index.html`, geen build-stap nodig).

## Netlify

Deze repo is klaar om direct te deployen:

- `netlify.toml` publiceert de repo-root als statische site
- alle routes vallen terug op `index.html` (SPA-redirect)

Koppelen: Netlify → **Add new site → Import an existing project** → GitHub →
`whateverthisshouldbe/app1vsseb` → branch `main`. Build command leeg laten,
publish directory `.`. Elke push naar `main` triggert daarna automatisch een
nieuwe deploy.

## Lokaal bekijken

Open `index.html` in de browser, of:

```sh
python3 -m http.server 8000
```
