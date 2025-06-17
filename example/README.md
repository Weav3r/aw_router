# aw_router Example Repo

This repository demonstrates how to use `aw_router`, a lightweight and expressive routing system designed for Dart and the Appwrite Functions runtime.

## Getting Started

### Prerequisites

- [Appwrite CLI](https://appwrite.io/docs/command-line)
- Dart SDK (if testing locally)
- An HTTP client (e.g. [Bruno](https://usebruno.com/), Postman, curl, Insomnia)

### Running without an appwrite environment

```bash
git clone https://github.com/Weav3r/aw_router
cd example
dart pub get

# run the example local file
dart run lib/main.local.dart
```



### Running with an appwrite environment

#### 1. Clone and Run the Example Locally

```bash
git clone https://github.com/Weav3r/aw_router
cd example
appwrite run function
```

> u26A0uFE0F Ensure the CLI generates the correct local `host:port` for the function when using your HTTP client.

#### 2. Test the Routes

You can test routes using any HTTP client. For example, using curl:

```bash
curl --request GET
  --url http://localhost:3000/products/
  --header 'authorization: valid-token'
```

---

## Optional: Test `AppwriteRouter`

If you'd like to test the dynamic routes using Appwrite's database integration:

### 1. Create a Test Project

Use the Appwrite Console or CLI to create a new project with the ID:

```text
660b7f66f282093298a
```

### 2. Push Project Config

Push the configuration defined in `appwrite.json`:

```bash
appwrite push
```

Choose at minimum:

```text
❯ Settings (Project)
  Collections (Databases)
```

> Push the `Functions` section only if you plan to deploy the function (instead of running locally).

### 3. Start the Function

Run the function locally:

```bash
appwrite run function
```

> u26A0uFE0F If you're deploying the function, push it twice to ensure all permissions/scopes are applied correctly.

### 4. Test Appwrite-Connected Routes

```bash
curl --request POST
  --url http://localhost:3000/appwrite/messages
  --header 'Content-Type: application/json'
  --data '{"content": "Hello, Appwrite!"}'
```

---

## Routes Showcase

This example includes:

- Basic text, JSON, and binary responses
- Route-level logging
- Custom middlewares
- Redirects
- Appwrite Database CRUD integration

Explore the different routers in `/example/routers`.
