# Guia de exposicion: Cafeteria OEA

## 1. Resumen del sistema

Cafeteria OEA es una aplicacion movil multiplataforma hecha con Flutter y Dart.
Permite iniciar sesion, consultar el menu, agregar productos al carrito, crear
ordenes, revisar el historial de pedidos y consultar el perfil. Los usuarios
con rol `admin` o `employee` tienen una seccion adicional para administrar
ordenes y productos, incluyendo lectura de codigos QR.

La aplicacion es el cliente movil: no accede directamente a la base de datos.
Se comunica con un servidor HTTP que expone endpoints PHP y devuelve JSON.

```text
Usuario
  |
  v
Flutter / Dart
  |  HTTP + JSON + Authorization
  v
API (cafeteriaoea.cloud)
  |
  v
Base de datos
```

La responsabilidad se divide asi:

- Flutter muestra pantallas, valida formularios y conserva el estado temporal.
- Los repositorios conocen los endpoints y convierten JSON en modelos Dart.
- `ApiClient` centraliza HTTP, autenticacion, errores y reintentos.
- La API valida permisos, reglas de negocio y acceso a la base de datos.

## 2. Tecnologias y dependencias

- **Flutter/Dart:** interfaz y logica multiplataforma.
- **Material 3:** widgets, tema, colores, navegacion y formularios.
- **http:** solicitudes `GET`, `POST` y `multipart/form-data`.
- **shared_preferences:** persistencia local de la sesion serializada.
- **flutter_secure_storage:** almacenamiento seguro de email y contrasena
  usados para renovar la sesion.
- **mobile_scanner:** lectura de codigos QR desde la camara.
- **qr_flutter:** generacion del QR que se presenta al recoger una orden.
- **image_picker:** seleccion de imagen desde galeria o camara.
- **intl:** formato de fechas de las ordenes.
- **flutter_test:** pruebas unitarias y de widgets.

La version minima del SDK Dart declarada en `pubspec.yaml` es `^3.13.4`.
La aplicacion usa `MaterialApp`, `FutureBuilder`, `StatefulWidget`,
`StatelessWidget`, `Form`, `Future`, `async/await` y modelos inmutables con
constructores `const`.

## 3. Arranque y configuracion global

### `lib/main.dart`

`main()` es el punto de entrada y ejecuta:

```dart
runApp(const CafeteriaApp());
```

No contiene logica de negocio. Su funcion es iniciar el arbol de widgets.

### `lib/app/cafeteria_app.dart`

`CafeteriaApp` es un `StatefulWidget` porque la pantalla inicial cambia cuando
se restaura, inicia o cierra una sesion.

Variables importantes de `_CafeteriaAppState`:

- `_authRepository`: repositorio de autenticacion.
- `_restoredSession`: `Future<AuthSession?>` que representa la restauracion.
- `_session`: sesion actualmente activa, o `null`.

Funciones:

- `initState()`: inicia `_restoreSession()`.
- `_restoreSession()`: llama a `AuthRepository.loadSession()` y actualiza
  `_session`.
- `_refreshToken()`: solicita una nueva clave; si la API devuelve `401`,
  limpia la sesion y vuelve al login.
- `_logout()`: elimina la sesion persistida y deja `_session` en `null`.
- `build()`: configura `MaterialApp`, titulo, tema y un `FutureBuilder`.

Estados de inicio:

1. Mientras se restaura la sesion aparece un `CircularProgressIndicator`.
2. Sin sesion valida se muestra `LoginPage`.
3. Con sesion valida se muestra `CafeteriaShell`.

### `lib/core/theme/app_theme.dart`

`AppTheme.light()` construye el `ThemeData` global:

- Material 3 activado.
- `ColorScheme.fromSeed` con color base marron/dorado.
- Fondo y `AppBar` sin elevacion.
- Tarjetas con bordes redondeados de 20 px.
- Campos de entrada rellenos y redondeados de 16 px.

Centralizar el tema permite cambiar la identidad visual sin editar cada pagina.

## 4. Cliente HTTP y manejo de errores

### `lib/core/network/api_client.dart`

`ApiClient` es la capa transversal de red. Sus miembros principales son:

- `baseUrl`: actualmente `http://10.0.2.2/cafeteriaoea.cloud`.
  `10.0.2.2` permite que un emulador Android acceda al servidor local del
  computador. En un telefono fisico, iOS, produccion o un servidor remoto debe
  cambiarse la configuracion.
- `_client`: instancia de `http.Client`, inyectable para pruebas.
- `token`: token opcional de la sesion.
- `onTokenExpired`: callback para renovar token despues de un `401`.

Tipos y funciones:

- `TokenRefreshCallback`: define `Future<String?> Function()`.
- `ApiException`: error de dominio con `message` y `statusCode`.
- `get(path, queryParameters)`: envia una solicitud GET.
- `post(path, body, queryParameters)`: codifica `body` como JSON y envia POST.
- `postMultipart(...)`: envia campos y, opcionalmente, una imagen.
- `_multipartRequest(...)`: construye el `MultipartRequest`.
- `_headers(requestToken)`: agrega el encabezado de autorizacion si hay token.
- `_uri(path, queryParameters)`: concatena la URL base, path y query string.
- `_send(...)`: ejecuta una solicitud y la reintenta una sola vez si recibe
  `401` y existe callback de renovacion.
- `_decodeResponse(response)`: decodifica JSON, rechaza JSON invalido y convierte
  HTTP no exitoso en `ApiException`.

El reintento es deliberadamente de una sola vez para evitar ciclos infinitos.
Si renovar falla, el error llega a la pantalla para que se muestre al usuario.

## 5. Organizacion por funcionalidades

La carpeta `lib/features/` usa una organizacion por feature:

```text
feature/
  presentation/  pantallas y widgets
  data/          repositorios y acceso a API
  domain/        modelos y reglas del dominio
```

No todas las funcionalidades necesitan las tres carpetas. La ventaja es que
cada concepto del negocio permanece agrupado y la interfaz no queda acoplada a
detalles de HTTP.

## 6. Autenticacion y sesion

Archivos:

- `features/auth/presentation/login_page.dart`
- `features/auth/data/auth_repository.dart`
- `features/auth/domain/user.dart`

### Modelo `User`

`User` contiene:

- `id: int`
- `name`
- `email`
- `phone`
- `role`
- `status`

`User.fromJson()` convierte valores numericos o texto a tipos Dart y usa
valores vacios/default cuando faltan campos. `toJson()` permite persistirlo.

### Modelo `AuthSession`

`AuthSession` contiene `token`, `expiresAt` y `user`.

- `apiKey`: getter que devuelve el token para los repositorios.
- `isExpired`: considera expirada la sesion si no existe fecha o si ya paso.
- `toJson()` y `fromJson()`: serializacion de la sesion.

### `AuthRepository`

Variables:

- `_client`: `ApiClient` reutilizable.
- `preferences`: dependencia opcional para pruebas.
- `_secureStorage`: almacenamiento seguro.
- `_sessionKey`, `_emailKey`, `_passwordKey`: claves de almacenamiento.
- `_refreshInFlight`: futura renovacion que ya esta en curso.

Funciones:

- `_storage()`: obtiene `SharedPreferences`.
- `login(email, password)`: llama a `/auth/login.php`, valida token/usuario,
  crea `AuthSession`, guarda la sesion y almacena credenciales seguras.
- `refreshToken()`: evita renovaciones simultaneas; varias solicitudes que
  reciben `401` esperan el mismo `Future<AuthSession>`.
- `_refresh()`: lee credenciales seguras y vuelve a ejecutar `login`.
- `saveSession(session)`: guarda la sesion como JSON.
- `loadSession()`: recupera, decodifica, valida expiracion y elimina datos
  corruptos o expirados.
- `getApiKey()`: devuelve el token guardado.
- `isSessionExpired()`: consulta la expiracion sin devolver el modelo.
- `clearSession()`: elimina sesion, email y contrasena.
- `me(token)`: consulta `/auth/me.php` y convierte el usuario.

### `LoginPage`

Es un `StatefulWidget` con:

- `_formKey`: valida el formulario.
- `_emailController` y `_passwordController`: controlan campos.
- `_isLoading`: deshabilita el boton durante la solicitud.
- `_error`: mensaje visible de autenticacion o conectividad.
- `_login()`: valida, llama al repositorio y ejecuta `onLoggedIn`.

Los controladores se liberan en `dispose()`. La pantalla no conoce la URL:
solo conoce `AuthRepository`.

## 7. Menu y productos

Archivos:

- `features/menu/presentation/menu_page.dart`
- `features/menu/data/product_repository.dart`
- `features/menu/data/mock_menu.dart`
- `features/menu/domain/menu_item.dart`

### Modelo `MenuItem`

Campos:

- `id`, `name`, `description`, `category`
- `price: int`
- `isAvailable: bool`
- `image: String?`

`fromJson()` acepta nombres alternativos en espanol e ingles (`nombre`,
`descripcion`, `categoria`, `precio`, `imagen`). `_parsePrice()` convierte
numeros o textos decimales a entero. `_parseImage()` busca `image_url`,
`image`, `image_path` o `imagen`.

`imageUrl` devuelve la URL completa: conserva una URL absoluta y agrega
`_baseUrl` a rutas relativas. El valor cero se muestra como “Precio pendiente”.

### `ProductRepository`

- `readAll()`: consulta `/products/read.php?id=` y acepta una lista directa o
  una lista dentro de `data`.
- `createProduct(...)`: envia `name`, `category`, `price`, `qty=99` e imagen
  opcional a `/products/create.php` mediante multipart.
- `updateProduct(...)`: usa la misma estructura contra
  `/products/update.php?id=<id>`.

El repositorio recibe el token y el callback de expiracion, por lo que todas
las operaciones de producto soportan renovacion automatica.

### `mock_menu.dart`

Define tres `MenuItem` de ejemplo (`mock-01` a `mock-03`) con precio cero.
Se usa en pruebas y demostraciones sin depender del servidor; no es el menu
real de produccion.

### `MenuPage`

Recibe `items`, `onAdd` y `onRefresh`. Usa `RefreshIndicator` y una lista de
tarjetas. `_MenuItemCard` muestra imagen, disponibilidad, nombre, descripcion,
precio y boton para agregar.

Los chips “Todos”, “Disponibles” y “Favoritos” y el campo de busqueda son
actualmente elementos visuales: sus callbacks no filtran la lista. Esto debe
explicarse como interfaz preparada, no como filtros terminados.

## 8. Shell, navegacion y carrito

### `CafeteriaShell`

Es el contenedor principal despues del login y conserva el estado de la
sesion. Sus variables son:

- `_selectedIndex`: pagina activa.
- `_cart`: lista temporal de `MenuItem`.
- `_menuFuture`: carga actual del menu.
- `_productRepository`: acceso a productos.
- `_profileFuture`: carga diferida del perfil.
- `_ordersRepository`: acceso a ordenes.
- `_ordersFuture`: carga de pedidos del usuario.

Funciones:

- `_canAccessAdmin`: devuelve true para roles normalizados `admin` o `employee`.
- `initState()`: crea repositorios y arranca la carga del menu.
- `_selectPage(index)`: cambia pagina; carga perfil al entrar al indice 3 y
  pedidos al entrar al indice 2.
- `_addToCart(item)`: agrega el producto, actualiza el badge y muestra SnackBar.
- `_refreshMenu()`: vuelve a consultar productos.
- `build()`: arma las paginas y la `NavigationBar`.

La navegacion contiene Menu, Carrito, Pedidos, Perfil y, solo para roles
permitidos, Admin. El carrito vive en memoria y se pierde al cerrar sesion o
reiniciar la aplicacion.

### `CartPage`

Recibe la lista del shell, la sesion y el callback de token. Sus miembros son:

- `_notesController`: notas de la orden.
- `_formKey`: clave del formulario.
- `_isLoading`: evita envios duplicados.
- `items`: getter sobre el carrito compartido.
- `totalPrice`: suma `item.price` con `fold`.
- `_removeItem(item)`: elimina un producto.
- `_createOrder()`: valida, crea la orden y limpia el carrito si todo sale bien.

La orden se envia mediante `OrdersRepository.createOrder`. La interfaz muestra
“Orden mock creada” porque el pago aun no esta integrado; la API de orden y sus
items si tienen llamadas reales.

## 9. Pedidos, estados y detalle

Archivos:

- `features/orders/data/orders_repository.dart`
- `features/orders/domain/order_item.dart`
- `features/orders/domain/order_line_item.dart`
- `features/orders/domain/order_status.dart`
- `features/orders/presentation/orders_page.dart`
- `features/orders/presentation/order_view.dart`

### Modelos

`OrderLineItem` representa una linea:
`id`, `orderId`, `productId`, `productName`, `price`, `quantity` y `subtotal`.

`OrderItem` representa una orden:
`id`, `userId`, `total`, `pickupCode`, `notes`, `status`, `createdAt`,
`updatedAt` y `orderItems`.

Sus funciones importantes son:

- `fromJson()`: convierte orden e items anidados.
- `_parseTotal()` y `_parseDateTime()`: normalizan dinero y fechas.
- `createdAtLabel` y `updatedAtLabel`: formato `dd/MM/yyyy hh:mm a`.
- `toJson()`: serializa una orden.
- `copyWith(status)`: crea una copia con otro estado.

`OrderStatus` refleja exactamente los valores de la API:

| Valor             | Etiqueta           | Significado                      |
| ----------------- | ------------------ | -------------------------------- |
| `pending_payment` | Pendiente de pago  | Orden creada sin pago confirmado |
| `paid`            | Pagado             | Pago recibido                    |
| `ready`           | Listo para recoger | Pedido preparado                 |
| `claimed`         | Entregado          | Pedido recogido                  |
| `cancelled`       | Cancelado          | Orden anulada                    |

`isFinal` identifica `claimed` y `cancelled`; `canCancel` identifica
`pendingPayment` y `paid`; `label` traduce el estado a la interfaz.

### `OrdersRepository`

- `fetchOrders()`: GET `/orders/read.php?user_id=<userId>`.
- `fetchAllOrders()`: GET `/orders/read.php` para administracion.
- `fetchOrderById(orderId)`: GET `/orders/read.php?order_id=<id>`.
- `updateOrderStatus(orderId, status)`: POST a
  `/orders/update.php?id=<id>` con `{status: status.value}`.
- `createOrderItem(...)`: POST `/order_items/create.php`.
- `createOrder(total, notes)`: POST `/orders/create.php`, extrae el id y crea
  secuencialmente un item por cada producto del carrito.
- `_parseId()`: valida que ids de orden y producto sean enteros.

### Pantallas de pedidos

`OrdersPage` es reutilizable. Recibe el futuro, `onRefresh`, textos de usuario
o administrador, `canUpdateStatus` y callback de cambio de estado. Mantiene
\_orders para conservar contenido mientras se refresca y muestra carga, error,
reintento, estado vacio o lista.

`_OrdersList` abre `OrderView` al tocar una tarjeta. La extension
`OrderStatusUi` asigna color e icono por estado.

`OrderView` muestra:

- QR generado por `QrImageView` usando el id de la orden.
- Items, cantidades y subtotales.
- Estado, fecha, codigo de recogida, notas y total.
- Selector de estado para personal autorizado.

`_updateStatus()` evita cambios duplicados, llama al repositorio, actualiza la
copia local y muestra resultado. El QR que se presenta para recoger usa
actualmente `order.id` como dato.

## 10. Perfil

Archivos:

- `features/profile/data/profile_repository.dart`
- `features/profile/domain/profile_item.dart`
- `features/profile/presentation/profile_page.dart`

`ProfileRepository.readProfile()` consulta `/auth/me.php` y requiere un objeto
`user` en la respuesta.

`ProfileItem` contiene `id`, `name`, `email`, `phone`, `role` e `isActive`.
Acepta claves alternativas (`nombre`, `correo`, `telefono`, `rol`) y considera
activo solo el estado `active`.

`ProfilePage` muestra encabezado, nombre, correo, tarjeta de “Editar Perfil” y
la opcion “Cerrar sesion”. El cierre pide confirmacion y ejecuta `onLogout`.
La edicion de perfil es actualmente una opcion visual sin pantalla de destino.

## 11. Administracion, QR y productos

### `AdminPage`

Recibe `OrdersRepository`, `ProductRepository` y `userRole`. Presenta:

1. **Escanear QR:** abre `QrScannerScreen`, busca la orden y abre `OrderView`.
2. **Ver Ordenes:** reutiliza `OrdersPage` con `fetchAllOrders()`.
3. **Mis productos:** abre `AdminProductsPage`.

`_canUpdateStatus` permite actualizar estados a `admin` y `employee`.
Los permisos reales tambien deben validarse en la API; ocultar la opcion en
Flutter no sustituye la autorizacion del servidor.

### `QrScannerScreen`

Usa `MobileScannerController` con `DetectionSpeed.noDuplicates`.

- `_handled`: bandera que evita procesar varias veces el mismo resultado.
- `scanAreaSize`: cuadrado de lectura de 250 px.
- `_onDetect(capture)`: toma el primer `rawValue` y lo devuelve con `Navigator.pop`.
- `dispose()`: libera la camara.
- `_OverlayPainter`: dibuja oscurecimiento y borde del area de escaneo.

Tambien hay un boton para activar o desactivar la linterna.

### `AdminProductsPage` y `ProductFormPage`

`AdminProductsPage` carga productos, permite refrescar, crear y editar.
`_openCreateProduct()`, `_editProduct()` y `_reloadProducts()` coordinan la
navegacion y recarga.

`ProductFormPage` usa controladores para nombre, categoria y precio:

- `_pickImage(source)`: usa galeria o camara y guarda la ruta local.
- `_chooseImageSource()`: muestra el bottom sheet de seleccion.
- `_required(value)`: valida texto obligatorio.
- `_positiveInteger(value)`: valida precio entero no negativo.
- `_submit()`: crea o actualiza usando multipart y devuelve `true`.

La API recibe `qty=99` en crear y actualizar. La pantalla no ofrece aun una
edicion de cantidad/disponibilidad independiente.

## 12. Endpoints usados

| Metodo         | Endpoint                         | Uso                      |
| -------------- | -------------------------------- | ------------------------ |
| POST JSON      | `/auth/login.php`                | iniciar sesion           |
| GET            | `/auth/me.php`                   | usuario/perfil actual    |
| GET            | `/products/read.php?id=`         | listar productos         |
| POST multipart | `/products/create.php`           | crear producto           |
| POST multipart | `/products/update.php?id=<id>`   | editar producto          |
| GET            | `/orders/read.php?user_id=<id>`  | pedidos del usuario      |
| GET            | `/orders/read.php`               | todos los pedidos, admin |
| GET            | `/orders/read.php?order_id=<id>` | detalle por QR           |
| POST JSON      | `/orders/create.php`             | crear cabecera de orden  |
| POST JSON      | `/order_items/create.php`        | crear item de orden      |
| POST JSON      | `/orders/update.php?id=<id>`     | actualizar estado        |

Todas las llamadas autenticadas agregan el token en el encabezado de
autorizacion. La URL usa HTTP y una direccion de desarrollo; para produccion
debe configurarse HTTPS y una base URL por ambiente.

## 13. Flujo completo para demostrar

1. **Inicio:** explicar `main()` y la restauracion en `CafeteriaApp`.
2. **Login:** mostrar validacion local y llamada a `/auth/login.php`.
3. **Menu:** explicar `ProductRepository`, `MenuItem` y carga desde API.
4. **Carrito:** agregar, eliminar, calcular `totalPrice` y escribir notas.
5. **Orden:** explicar la cabecera y los items enviados por separado.
6. **Pedidos:** abrir historial, detalle, estados y QR de recogida.
7. **Perfil:** mostrar consulta diferida a `/auth/me.php` y cerrar sesion.
8. **Admin:** entrar con rol autorizado, listar ordenes, escanear QR y cambiar
   estado.
9. **Productos:** crear o editar nombre, categoria, precio e imagen.

## 14. Pruebas existentes

- `test/api_client_test.dart`: verifica que un `401` provoque una sola
  renovacion y un segundo request con el token nuevo.
- `test/order_item_test.dart`: verifica el parseo de una orden con item anidado,
  dinero decimal y fechas.
- `test/widget_test.dart`: monta el shell con `mockMenu`, comprueba el menu y
  verifica que un producto llegue al carrito.

Estas pruebas muestran inyeccion de dependencias (`http.Client`, futuros de
menu) y permiten probar sin depender siempre de la API real.

## 15. Limitaciones y puntos pendientes que deben mencionarse

- El pago no esta implementado; la orden se crea, pero se informa como mock y
  pendiente de pago.
- La busqueda y los filtros del menu son visuales y aun no filtran.
- “Editar Perfil” no tiene flujo implementado.
- El carrito es memoria local, sin cantidades agrupadas ni persistencia.
- La administracion de productos fija `qty=99`.
- La base URL esta fija para desarrollo y usa HTTP.
- Las credenciales se guardan en almacenamiento seguro para renovar el token;
  esto debe revisarse segun la politica de seguridad de produccion.
- El backend debe volver a validar rol, token, estados y datos recibidos.

## 16. Respuesta corta para profesores

> Cafeteria OEA es un cliente Flutter organizado por funcionalidades. El
> usuario interactua con pantallas que llaman repositorios; los repositorios
> usan un cliente HTTP centralizado para enviar JSON o multipart a una API. La
> API valida autenticacion y permisos, consulta o modifica la base de datos y
> devuelve JSON. Ese JSON se convierte en modelos como `MenuItem`,
> `AuthSession` y `OrderItem`, y la interfaz muestra el resultado. La sesion
> se guarda localmente, se renueva una vez cuando expira y el acceso
> administrativo se habilita segun el rol, aunque la autorizacion definitiva
> corresponde al servidor.
