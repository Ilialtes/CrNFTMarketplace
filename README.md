# Mod 3 - Trabajo Final ETH Kipu


## Integrantes:
- https://github.com/Ilialtes - Josue Perez Valverde
- https://github.com/shuncko - Alfredo Li Avila
- https://github.com/jsandinoDev - Josue Sandino Jaen


## Descripcion

El contrato se basa en un Marketplace de NFTs, en el cual se pueden realizar diferentes funcionalidades como: mint, list, purchase, entre otras. Este contrato incluye importaciones de contratos y librerías de OpenZeppelin. Además, posee diversos patrones y funcionalidades para asegurar su seguridad.

## Funcionalidades

- Mint (crear) NFTs proporcionando una URI única.
- Listar NFTs para la venta, especificando un precio.
- Comprar NFTs listados a través de pagos en ETH.
- Implementar una comisión (fee) que se aplica en cada venta, la cual es transferida al propietario del contrato.
- Pausar o despausar el contrato, deteniendo funciones críticas cuando sea necesario, solo por el propietario.



## Razonamiento detrás del diseño

### Implementacion de patrones
- **ReentrancyGuard**: Implementacion del patron para proteger contra ataques de reentrada durante la compra de un NFT, evitando asi que se puedan ejecutar multiples funciones operaciones simultaneas.
- **Ownable**: Utilizado para asegurar que solo el propietario del contrato pueda realizar ciertas funcionalidades
- **Pausable**: Patrón utilizado para emergencias en las cuales se necesite detener las funciones claves en caso de errores o situaciones imprevistas.


### Uso de mappings 
- Almacenamiento de NFTs y listados mediante mappings que aseguran la eficiencia en términos de gas y permiten fácil acceso a la información.

### Separación de responsabilidades y funciones internas
- Algunas funciones como **_removeTokerFromOwner** estan desarrolladas como internas para modulizar y mejorar la claridad del codigo

### Eventos para transparencia
- Creación de eventos que permiten una notificación transparente de la interacción con el contrato.

### Uso de bibliotecas seguras
- Uso de OpenZeppelin para asegurar la seguridad y el seguimiento de estándares.

