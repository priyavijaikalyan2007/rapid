# Outcrop Inc website

This directory contains the static catalog, support, and legal website for the applications in this repository.

The site loads the Enterprise Application theme directly from `https://static.outcrop.us`.

The website uses Google Analytics only for aggregate website metrics. The applications do not contain Google Analytics or app telemetry.

The analytics configuration disables Google signals and advertising personalization. The privacy policy explains the website data collection and Google Analytics cookies.

The `static.outcrop.us` hostname must be a Custom Domain on the deployed theme Worker. A Domain Name System CNAME alone does not route the hostname to that Worker.

Remove the existing CNAME before you add the Custom Domain. Cloudflare will create the required Domain Name System record and certificate.

The Wrangler configuration also disables Wrangler usage metrics and dependency instrumentation for this project.

The website uses the theme's ThemeToggle, MarketingHero, and SiteFooter components directly from the CDN.

MarketingHero and SiteFooter use their canonical static markup. They require their CDN stylesheets but no component scripts.

The selected mode uses local browser storage. The preference remains on the visitor's device.

## Structure

```text
src/web/
├── VERSION
├── site.config.json
├── site/
│   ├── index.html
│   ├── apps/cropprint/index.html
│   ├── privacy/index.html
│   ├── terms/index.html
│   ├── support/index.html
│   ├── 404.html
│   ├── _headers
│   ├── robots.txt
│   ├── security.txt
│   ├── .well-known/security.txt
│   ├── llms.txt
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
- `dunsNumber` and `dnbProfileUrl` define the Dun & Bradstreet profile details.
- `washingtonUbiNumber` and `washingtonRegistrationUrl` define the state registration details.
- `legalEffectiveDate` sets the policy and terms effective date.
- `googleAnalyticsId` sets the website-only Google Analytics property.
- `apps` defines each app card and its icon.

The public name is `Outcrop Inc`. The canonical website is `https://outcrop.us`.

The site uses `admin@outcrop.us` for legal and support contact.

## App catalog

Add one object to the `apps` array for each application. Point `iconSource` to the app icon in this repository.

Set `pagePath` to the directory for the app page. Add a long-form page at the same path under `site`.

The build copies the icon into the generated website. The CropPrint card and page use the macOS application icon.

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
5. Validate the approved analytics property and reject unapproved tracking services.
6. Validate the crawler, sitemap, security contact, and AI summary files.

The semantic version, build number, and Git SHA appear in each page footer.

The build number uses the Git commit time in `YYYYMMDDHHMMSS` format. The time is in Coordinated Universal Time.

Cloudflare supplies the source SHA through `WORKERS_CI_COMMIT_SHA`. Local builds read the same value from Git and add `-dirty` when needed.

Set `SITE_BUILD_NUMBER` only when a controlled build requires an explicit 14-digit number.

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

## Cloudflare builds

Cloudflare Workers Builds deploys the website after a successful build from `main`.

The Cloudflare project uses `src/web` as its root directory. It runs `npm run build`, then `npx wrangler deploy`.

The repository does not use a GitHub Actions workflow to deploy the website.

## Legal review

The privacy policy matches the current local-processing design. The terms and policy are general templates, not legal advice.

Review the publisher identity, Washington jurisdiction, third-party services, and store behavior before publication.

## Theme components

MarketingHero provides the responsive home-page introduction and privacy callout layout.

SiteFooter provides organization details, navigation, registration links, legal links, contact details, and build information on every page.
