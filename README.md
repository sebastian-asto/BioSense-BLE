# BioSense BLE

Sistema inalámbrico de temperatura, humedad, presión relativa y voltaje de
batería. Está formado por un sensor basado en nRF52840 y una aplicación Flutter
que recibe los datos directamente desde la publicidad BLE.

## Proyectos

| Carpeta | Descripción |
| --- | --- |
| [BioSense_BLE_code_nrf52840/](BioSense_BLE_code_nrf52840/README.md) | Firmware Zephyr/nRF Connect SDK para el Ebyte E73-2G4M08S1C |
| [biosense/](biosense/README.md) | Aplicación Flutter para Android e iOS |

Cada proyecto contiene su propio README con instrucciones de compilación y uso.

## Arquitectura

```text
HTU21D (0x40) ----\
                   \
WF100DPZ (0x6D) ----> E73-2G4M08S1C / nRF52840
VDD por SAADC ------/      |
                           | Manufacturer Data BLE, -20 dBm
                           | ráfaga de 2 s cada 60 s
                           v
                    Aplicación Flutter
```

No se establece una conexión BLE. El teléfono solamente escanea los anuncios,
lo que simplifica el protocolo y permite apagar la radio entre mediciones.

## Hardware principal

- Módulo Ebyte E73-2G4M08S1C con nRF52840.
- HTU21D para temperatura y humedad, dirección I2C `0x40`.
- WF100DPZ para presión relativa, dirección I2C `0x6D`.
- Bus I2C: SCL P0.26 y SDA P0.06 a 100 kHz.
- LED activo en alto conectado a P1.10.
- UART TX de diagnóstico en P0.20 a 115200 baudios.
- Cristal LF externo de 32.768 kHz entre XL1 y XL2.
- Alimentación prevista mediante CR2032.

## Estrategia de bajo consumo

- Potencia BLE configurada en **-20 dBm** para alcance corto.
- Ráfaga publicitaria de 2 segundos cada 60 segundos.
- Publicidad no conectable; no mantiene enlaces activos.
- LFCLK proveniente del cristal externo de 32.768 kHz.
- CPU inactiva entre ciclos mediante el kernel de Zephyr.
- Consola, UART, banner y logs deshabilitados en producción.
- LED apagado durante la operación normal.

El alcance real no depende únicamente de la potencia: también influyen la
antena del módulo, la PCB, la carcasa, el cuerpo humano, el ruido de 2.4 GHz y
el teléfono. Debe validarse el objetivo de 1 a 2 metros con el producto
ensamblado.

## Datos transmitidos

La trama BLE v1 contiene:

- Device ID y número de secuencia.
- Temperatura en centésimas de grado Celsius.
- Humedad en centésimas de porcentaje.
- Presión relativa en centésimas de kPa.
- VDD en milivoltios.
- Indicador de batería baja por debajo de 2.4 V.

Durante desarrollo se usa el Company ID `0xFFFF`. Antes de comercializar el
producto debe sustituirse por un Company Identifier asignado o por otro formato
de publicidad que no reserve indebidamente ese identificador.

## Inicio rápido

Firmware:

```powershell
cd BioSense_BLE_code_nrf52840
west build -p always -b supermini_custom/nrf52840 .
west flash -d build -r pyocd
```

Aplicación:

```powershell
cd biosense
flutter pub get
flutter run
```

Al encender el sensor debe estar sin presión aplicada para que el WF100DPZ haga
su tara. Mantenga la aplicación abierta; una medición nueva puede tardar hasta
60 segundos.
