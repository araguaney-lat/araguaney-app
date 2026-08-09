# Security Policy

## Reporting a vulnerability

If you find a vulnerability, report it privately:

- **GitHub**: use [private vulnerability reporting](../../security/advisories/new) (*Security* tab → *Report a vulnerability*). This is the preferred channel.
- **Email**: security@araguaney.lat, subject `[SECURITY] araguaney-app`.

Please do not open public issues or pull requests for security problems. We will acknowledge reports as quickly as we can and keep you informed of the resolution.

## Scope

This repository contains the mobile client only. Vulnerabilities in the API, the web application, or the server infrastructure belong to the [backend repository](https://github.com/araguaney-lat/araguaney) and should be reported through its security policy; reports sent to either channel will be routed correctly in any case.

Areas of particular interest for this client:

- Token storage and session handling on the device (Keychain / Android Keystore usage).
- The offline capture queue: idempotency, attribution of queued captures to the correct user, and behavior when a device is shared by several operators.
- Anything that could cause the client to present data from one collection center to a user of another.

## Reportar en español

Los reportes en español son bienvenidos por los mismos canales.
