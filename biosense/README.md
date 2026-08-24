# Aplicación BioSense

Aplicación Flutter que escucha la publicidad BLE del sensor BioSense sin
establecer una conexión. Presenta temperatura, humedad, presión relativa y
voltaje de alimentación del nRF52840.

## Funciones

- Escaneo BLE continuo en Android e iOS.
- Filtro exclusivo para la trama BioSense.
- Tarjetas animadas para temperatura, humedad, presión y batería.
- Indicador circular que parpadea al aceptar una medición nueva.
- Visualización de RSSI, identificador BLE y hora de recepción.
- Aviso de batería baja cuando el firmware reporta VDD menor de 2.4 V.
- Rechazo de paquetes repetidos pertenecientes a la misma ráfaga publicitaria.

## Identificación BLE

Solo se aceptan Manufacturer Data que cumplan todos estos valores:

| Campo | Valor esperado |
| --- | --- |
| Company ID de desarrollo | `0xFFFF` |
| Magic | ASCII `BS` |
| Versión | `1` |
| Device ID | `0xB1050001` |

La aplicación muestra el identificador proporcionado por el sistema operativo,
pero no lo utiliza como filtro. La dirección puede cambiar y en iOS no se
expone como una dirección MAC BLE convencional.

## Frecuencia de actualización

El sensor mide cada 60 segundos y anuncia la trama durante 2 segundos. Por eso
el primer dato puede tardar hasta un minuto. La aplicación descarta las copias
de una misma secuencia recibidas durante la ráfaga y anima el indicador solo al
llegar una muestra nueva.

## Requisitos

- Flutter compatible con Dart `^3.12.2`.
- Teléfono físico con BLE; el escaneo no funciona en la mayoría de emuladores.
- Bluetooth y permisos de dispositivos cercanos habilitados.
- En Android 11 o anterior también puede solicitarse ubicación para escanear.

Los permisos BLE ya están declarados en Android e iOS dentro del proyecto.

## Ejecutar

```powershell
flutter pub get
flutter run
```

## Verificar

```powershell
flutter analyze
flutter test
```

## Generar APK de depuración

```powershell
flutter build apk --debug
```

El APK queda en:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Correspondencia de datos

| Dato | Codificación BLE | Presentación |
| --- | --- | --- |
| Temperatura | Entero con signo, 0.01 °C | °C |
| Humedad | Entero sin signo, 0.01 %RH | % |
| Presión relativa | Entero con signo, 0.01 kPa | kPa |
| VDD | Entero sin signo, 1 mV | V |

El protocolo completo se documenta en el proyecto de firmware, en
[docs/biosense_ble_frame.md](../BioSense_BLE_code_nrf52840/docs/biosense_ble_frame.md).
