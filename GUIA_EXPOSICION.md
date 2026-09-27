# Guia de exposicion: Cafeteria OEA

## 1. Que es el proyecto

Cafeteria OEA es una aplicacion movil desarrollada con Flutter. Su objetivo es
permitir que los usuarios consulten el menu de la cafeteria, seleccionen
productos, armen un carrito y gestionen su informacion de perfil. Tambien
incluye un espacio administrativo con una funcionalidad de lectura de codigos
QR.

La aplicacion movil es el cliente. No se conecta directamente a la base de
datos. La comunicacion se realiza con un servidor API, que recibe las
solicitudes de la aplicacion, consulta o modifica la base de datos y devuelve
una respuesta en formato JSON.

La idea principal para explicar el sistema es:

```text
Usuario
  |
  v
Aplicacion Flutter (cliente movil)
  |
  | HTTP/JSON + token Bearer
  v
Servidor API
  |
  v
Base de datos
```

Cuando se consulta informacion, el recorrido de regreso es:

```text
Base de datos -> API -> respuesta JSON -> Flutter -> pantalla
```

Cuando se envia informacion, por ejemplo las credenciales o una orden, el
recorrido es:

```text
Flutter -> solicitud HTTP con JSON -> API -> validacion y escritura en DB
       <- respuesta JSON con resultado o error <-
```

## 2. Tecnologias principales

- **Flutter y Dart:** construccion de la aplicacion multiplataforma.
- **Material:** componentes visuales y navegacion de la interfaz.
- **HTTP:** comunicacion entre la aplicacion y el servidor API.
- **JSON:** formato usado para enviar y recibir datos.
- **Shared Preferences:** almacenamiento local de la sesion iniciada.
- **Mobile Scanner:** lectura de codigos QR desde la pantalla administrativa.

Las dependencias principales se declaran en `pubspec.yaml`.

## 3. Estructura general del proyecto

### `lib/`

Contiene el codigo fuente de la aplicacion Flutter. La organizacion se hace
por responsabilidades y por funcionalidades, para evitar que toda la logica
quede mezclada en una sola pantalla.

### `lib/main.dart`

Es el punto de entrada de Flutter. Su responsabilidad es iniciar la aplicacion
ejecutando `CafeteriaApp`.

En la exposicion se puede decir que `main.dart` funciona como el arranque del
cliente, mientras que la configuracion y las decisiones de pantalla viven en
la capa `app`.

### `lib/app/`

Contiene la configuracion global de la aplicacion.

- `cafeteria_app.dart` crea el `MaterialApp`.
- Aplica el tema visual global.
- Intenta restaurar una sesion guardada.
- Muestra un indicador de carga mientras verifica la sesion.
- Dirige al usuario al login si no hay una sesion valida.
- Dirige al usuario a `CafeteriaShell` si la sesion existe y no ha expirado.

Esta capa decide el estado inicial de la aplicacion, pero no deberia contener
la logica detallada de cada funcionalidad.

### `lib/core/`

Contiene elementos reutilizables y transversales. Son piezas que pueden ser
utilizadas por varias funcionalidades.

#### `lib/core/network/`

Aqui se encuentra `api_client.dart`, el cliente HTTP centralizado.

Sus responsabilidades son:

- Definir la URL base del servidor API.
- Construir las URL de cada endpoint.
- Ejecutar solicitudes `GET` y `POST`.
- Enviar el token de autenticacion como `Authorization: Bearer <token>`.
- Codificar los datos enviados como JSON.
- Decodificar las respuestas JSON.
- Detectar codigos HTTP fuera del rango exitoso.
- Convertir problemas de comunicacion o respuestas invalidas en `ApiException`.

La URL configurada actualmente es `http://10.0.2.2/api.cafeteria.test/`. En un
emulador Android, `10.0.2.2` permite acceder al servidor que corre en la
maquina de desarrollo. En otro dispositivo o entorno esta direccion puede
necesitar cambiarse.

#### `lib/core/theme/`

Contiene `app_theme.dart`, donde se define el estilo visual general: colores,
tipografias, componentes y apariencia Material. Centralizar el tema evita
repetir estilos en cada pantalla.

### `lib/features/`

Agrupa las funcionalidades del sistema. Cada feature puede contener sus
propias capas `presentation`, `data` y `domain`.

Esta organizacion se conoce como una estructura orientada a funcionalidades:
todo lo relacionado con una parte del negocio permanece cerca, en lugar de
separar globalmente todos los widgets, todos los modelos y todos los servicios.

#### `features/auth/`

Gestiona autenticacion y sesion.

- `presentation/login_page.dart`: formulario de inicio de sesion y mensajes de
  error para el usuario.
- `data/auth_repository.dart`: envia email y contrasena a
  `/auth/login.php`, guarda la sesion localmente y consulta el usuario actual
  mediante `/auth/me.php`.
- `domain/user.dart`: modelo de datos del usuario.

Despues de iniciar sesion, la API devuelve un token, la informacion del usuario
y una fecha de expiracion. La aplicacion guarda esos datos con
`SharedPreferences` para poder restaurar la sesion al abrirse nuevamente.

#### `features/menu/`

Gestiona el menu y los productos.

- `presentation/menu_page.dart`: presenta los productos y permite agregarlos al
  carrito.
- `data/product_repository.dart`: consulta `/products/read.php`.
- `data/mock_menu.dart`: datos de apoyo para pruebas o presentaciones sin
  depender completamente del servidor.
- `domain/menu_item.dart`: representa un producto con id, nombre, descripcion,
  categoria, precio y disponibilidad.

El repositorio recibe JSON desde la API y lo transforma a objetos `MenuItem`.
La pantalla trabaja con esos objetos, no con mapas JSON directamente.

#### `features/cart/`

Gestiona la seleccion temporal de productos.

- `presentation/cart_page.dart`: muestra los productos seleccionados, permite
  quitarlos, recibe notas, calcula el total y ofrece la accion de generar la
  orden.

El carrito vive actualmente en el estado de `CafeteriaShell`, por lo que se
comparte entre la pantalla de menu y la pantalla de carrito durante la sesion
de uso.

#### `features/orders/`

Representa la funcionalidad de pedidos.

- `presentation/orders_page.dart`: pantalla destinada a mostrar pedidos.
- `data/orders_repository.dart`: contiene la integracion para crear una orden
  mediante `/orders/create.php` y sus items mediante
  `/order_items/create.php`.
- `domain/order_item.dart`: modelo relacionado con los items de una orden.

El repositorio ya prepara el envio de la orden y de sus productos a la API.
Sin embargo, la interfaz actual todavia muestra el mensaje de orden mock y el
flujo de pedidos requiere terminar su activacion para presentarse como una
funcionalidad completa de produccion.

#### `features/profile/`

Gestiona la informacion del usuario autenticado.

- `presentation/profile_page.dart`: muestra los datos del perfil.
- `data/profile_repository.dart`: consulta `/auth/me.php` usando el token.
- `domain/profile_item.dart`: modelo de los datos del perfil.

La consulta del perfil se realiza cuando el usuario entra a esa seccion, en vez
de cargarla innecesariamente desde el inicio.

#### `features/admin/`

Contiene las funciones destinadas al rol administrativo.

- `presentation/admin_page.dart`: muestra opciones administrativas.
- `presentation/scanner_page.dart`: abre la camara, detecta un codigo QR y
  devuelve el valor leido a la pantalla anterior.

El lector QR usa `mobile_scanner` y evita procesar varias veces el mismo codigo
con una bandera de control. La opcion de ver ordenes administrativas todavia
funciona como espacio preparado para una ampliacion.

#### `features/shell/`

Contiene `cafeteria_shell.dart`, que funciona como contenedor principal despues
del login.

Sus responsabilidades son:

- Mantener la navegacion inferior.
- Cambiar entre menu, carrito, pedidos, perfil y administracion.
- Mantener la lista temporal del carrito.
- Cargar el menu mediante `ProductRepository`.
- Cargar el perfil cuando el usuario selecciona esa seccion.
- Enviar la sesion autenticada a las pantallas que necesitan el token.

El shell es una pieza de composicion: conecta las pantallas, repositorios y
estado de la sesion, pero cada feature conserva su propia responsabilidad.

## 4. Que significan `presentation`, `data` y `domain`

No todas las features tienen exactamente las tres carpetas, pero el criterio
es el siguiente:

### `presentation`

Es la capa visible. Incluye paginas, widgets, formularios, botones, estados de
carga y mensajes de error. Su objetivo es recibir acciones del usuario y
mostrar resultados.

### `data`

Es la capa de acceso a datos. Incluye repositorios y la comunicacion con la API.
Un repositorio sabe que endpoint consultar y como interpretar la respuesta,
pero la pantalla no necesita conocer los detalles de HTTP.

### `domain`

Es la capa de modelos del negocio. Define objetos como `User`, `MenuItem`,
`ProfileItem` y `OrderItem`. Estos objetos representan conceptos reales del
sistema y ayudan a trabajar con datos tipados y ordenados.

## 5. Flujo completo de autenticacion

1. El usuario escribe email y contrasena en `LoginPage`.
2. `LoginPage` llama a `AuthRepository.login`.
3. `AuthRepository` usa `ApiClient.post` contra `/auth/login.php`.
4. La API valida las credenciales contra la base de datos.
5. La API devuelve token, usuario y expiracion en JSON.
6. La aplicacion convierte la respuesta en `AuthSession`.
7. `AuthSession` se guarda localmente con `SharedPreferences`.
8. `CafeteriaApp` actualiza su estado y muestra `CafeteriaShell`.

Al volver a abrir la aplicacion, se intenta recuperar la sesion local. Si el
token esta vencido o el contenido guardado es invalido, se elimina y se vuelve
a solicitar el login.

## 6. Flujo de consulta del menu

1. `CafeteriaShell` obtiene el token de la sesion.
2. Crea `ProductRepository` con ese token.
3. El repositorio consulta `/products/read.php` mediante `ApiClient`.
4. La API consulta los productos en la base de datos.
5. La respuesta JSON llega a Flutter.
6. `ProductRepository` convierte cada registro en un `MenuItem`.
7. `MenuPage` muestra los productos y permite agregarlos al carrito.

## 7. Flujo de envio de una orden

El flujo preparado para la integracion es:

1. El usuario selecciona productos.
2. Los productos se almacenan temporalmente en el carrito.
3. El usuario agrega notas y confirma la orden.
4. `OrdersRepository.createOrder` envia total y notas a
   `/orders/create.php`.
5. La API crea la orden en la base de datos y devuelve su id.
6. Por cada producto, `createOrderItem` envia la informacion a
   `/order_items/create.php`.
7. La API guarda cada item relacionado con la orden.
8. Flutter informa el resultado y actualiza el estado del carrito.

Para la exposicion se debe aclarar que este flujo esta parcialmente integrado:
el repositorio contiene las llamadas reales, pero la interfaz actual conserva
un mensaje de orden mock y no debe describirse como un proceso de pago
finalizado. El pago aparece expresamente como pendiente.

## 8. Como explicar la seguridad y los errores

- El token de sesion no se envia como un parametro visible de la URL; se envia
  en el encabezado HTTP `Authorization`.
- La API es quien debe validar el token, permisos, datos y reglas de negocio.
- Flutter valida la respuesta recibida antes de convertirla a modelos.
- Los codigos HTTP de error se convierten en `ApiException`.
- La interfaz muestra estados de carga y mensajes cuando no hay conexion o la
  respuesta no tiene el formato esperado.
- La contrasena se envia a la API para que el servidor la valide; la aplicacion
  no debe conectarse directamente a la base de datos ni contener credenciales
  de base de datos.

En un entorno real de produccion, la API debe publicarse usando HTTPS y la URL
debe configurarse de acuerdo con el ambiente: desarrollo, pruebas o produccion.

## 9. Recorrido recomendado para la demostracion

1. Mostrar el login y explicar que las credenciales viajan a la API.
2. Entrar al menu y esperar la carga de productos desde el servidor.
3. Agregar un producto al carrito y explicar que esta seleccion es estado local
   de la aplicacion.
4. Abrir el carrito, mostrar el calculo del total y las notas.
5. Mostrar el perfil y explicar que se consulta con el token de la sesion.
6. Abrir administracion y demostrar el acceso al lector QR.
7. Explicar la diferencia entre funcionalidades terminadas, integraciones
   preparadas y funcionalidades pendientes.

## 10. Ideas clave para decir a los profesores

- La aplicacion esta separada por funcionalidades y responsabilidades.
- Flutter se ocupa de la experiencia del usuario y el servidor API se ocupa del
  acceso a datos y las reglas del backend.
- La base de datos no se expone directamente al cliente movil.
- Los repositorios aislan la comunicacion con los endpoints.
- Los modelos de `domain` permiten transformar JSON en objetos claros del
  negocio.
- La sesion se mantiene mediante un token con fecha de expiracion y un
  almacenamiento local.
- La arquitectura permite cambiar la interfaz sin reescribir el acceso a
  datos, y cambiar endpoints sin llenar las pantallas de codigo HTTP.
- El proyecto tiene una base funcional y puntos de extension definidos para
  terminar pedidos, consulta administrativa de ordenes y pago.

## 11. Respuesta corta para la pregunta "como funciona"

> El usuario interactua con una aplicacion Flutter organizada por
> funcionalidades. La aplicacion envia solicitudes HTTP en formato JSON al
> servidor API, incluyendo el token de autenticacion cuando corresponde. El
> servidor valida la solicitud, consulta o modifica la base de datos y
> devuelve una respuesta JSON. Los repositorios transforman esa respuesta en
> modelos de dominio y las pantallas muestran el resultado al usuario. Para
> enviar informacion ocurre el mismo proceso en sentido contrario: la
> aplicacion construye el JSON, la API lo valida y lo guarda en la base de
> datos.
