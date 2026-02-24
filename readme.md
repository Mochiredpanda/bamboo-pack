# Bamboo Pack

A native macOS/iOS Bring-Your-Own-Key (BYOK) parcel tracking app designed for personalized package management. Bamboo Pack operates entirely on the client side, utilizing a local database to keep tracking data private, customizable, and independent of centralized servers.

## Key Features

* **Local Database & Directional Data:** Manage incoming and outgoing parcels (tracking returns or packages sent to others) entirely on your device. Features custom and smart categorization tailored for personal lifestyle, as well as for professional enterprise logistics.
* **Scalable Architecture:** Open-Closed Principle. Designed with an adapter pattern that allows for the integration of new API suppliers without modifying the core UI or local database layers. Extensible for developers, small merchants, or middleware docking.
* **Purely Client-Side (BYOK):** Prioritizing privacy. Zero server dependency. Data management is handled directly on your device. Bring your own API key to track packages without app-specific subscription fees or centralized server costs.

## Current Status

Bamboo Pack is currently under active development. Ongoing work focuses on:

* Global polling and webhooks supports.
* Bidirectional data management.
* Expanded API supplier support.

## License

This project is licensed under the MIT License.