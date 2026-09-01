# Outcrop Inc website

This directory contains the static catalog, support, and legal website for the applications in this repository.

The site loads the Enterprise Application theme directly from `https://static.outcrop.us`.

The site does not load Google Fonts, analytics, advertising, or tracking scripts.

The `static.outcrop.us` hostname must be a Custom Domain on the deployed theme Worker. A Domain Name System CNAME alone does not route the hostname to that Worker.

Remove the existing CNAME before you add the Custom Domain. Cloudflare will create the required Domain Name System record and certificate.

The Wrangler configuration also disables Wrangler usage metrics and dependency instrumentation for this project.

The website uses the theme's ThemeToggle component. It supports light, automatic, and dark modes.

The selected mode uses local browser storage. The preference remains on the visitor's device.

## Structure

```text
src/web/
├── VERSION
├── site.config.json
├── site/
│   ├── index.html
│   ├── privacy/index.html
│   ├── terms/index.html
│   ├── support/index.html
│   ├── 404.html
│   ├── _headers
│   ├── assets/
│   └── css/
├── scripts/
├── build.sh
├── clean.sh
├── preview.sh
├── deploy.sh
├── package.json
└── wrangler.jsonc
```

The `dist` directory contains generated files. Git ignores this directory.

Run `./clean.sh` to remove `dist`, `.wrangler`, `node_modules`, and macOS metadata. The script preserves all source files.

## Public settings

Edit `site.config.json` before the first public deployment.

Set these values:

- `organizationName` sets the public publisher name.
- `siteUrl` records the final website address.
- `contactEmail` sets the public legal and support address.
- `legalEffectiveDate` sets the policy and terms effective date.
- `apps` defines each app card and its icon.

The public name is `Outcrop Inc`. The canonical website is `https://outcrop.us`.

The site uses `admin@outcrop.us` for legal and support contact.

## App catalog

Add one object to the `apps` array for each application. Point `iconSource` to that app's actual icon in this repository.

The build copies the icon into the generated website. For example, the CropPrint card uses its macOS application icon.

## Build and test

Run these commands from `src/web`:

```sh
npm install
./build.sh web
```

The build performs these tasks:

1. Generate the pages from the templates and site configuration.
2. Copy each application icon from its asset catalog.
3. Link to the Enterprise Application theme on its Content Delivery Network.
4. Validate local links, required page metadata, and image text alternatives.
5. Reject known analytics and tracking scripts.

The site version and Git SHA appear in each page footer.

## Local preview

Install the Node.js dependencies once. Then start the Cloudflare development server:

```sh
npm install
./preview.sh
```

Wrangler prints the local address. Press `Ctrl+C` to stop the server.

## Cloudflare deployment

Authenticate Wrangler before the first local deployment:

```sh
npx wrangler login
```

Check the upload without changing Cloudflare:

```sh
./deploy.sh --dry-run
```

Deploy the website:

```sh
./deploy.sh
```

The Wrangler configuration defines both production hostnames:

- `outcrop.us`
- `www.outcrop.us`

Add `outcrop.us` to Cloudflare before the first deployment. Remove conflicting Domain Name System records for either hostname.

## GitHub Actions

The website workflow deploys changes from `main`. It remains disabled until the repository variable is enabled.

Create this repository variable:

- `ENABLE_WEBSITE_PUBLISH` with value `true`

Create these encrypted repository secrets:

- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_API_TOKEN`

Use a Cloudflare API token that can edit Workers scripts for the target account.

## Legal review

The privacy policy matches the current local-processing design. The terms and policy are general templates, not legal advice.

Review the publisher identity, Washington jurisdiction, third-party services, and store behavior before publication.

## Theme feature requests

See `THEME_FEATURE_REQUESTS.md` for proposed MarketingHero and SiteFooter components.

Bootstrap already provides the other primitives used by this site. The requests do not duplicate Bootstrap navigation, cards, badges, buttons, or grids.
