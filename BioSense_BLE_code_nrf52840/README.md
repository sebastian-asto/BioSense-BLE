# Firmware BioSense para nRF52840

Firmware de ultra bajo consumo para el módulo Ebyte **E73-2G4M08S1C**, basado
en el Nordic nRF52840. Cada 60 segundos toma una muestra ambiental y la
publica mediante BLE sin establecer una conexión.

## Funciones

- Temperatura y humedad con HTU21D/SHT21 en `0x40`.
- Presión relativa con WF100DPZ en `0x6D`.
- Medición interna de VDD mediante SAADC.
- Publicidad BLE no conectable durante 2 segundos por muestra.
- Potencia de transmisión fija en **-20 dBm**.
- LFCLK mediante cristal externo de **32.768 kHz**.
- Consola, UART y logs desactivados en producción.

## Hardware y pines

| Función | Pin nRF52840 | Observación |
| --- | --- | --- |
| I2C SCL | P0.26 | 100 kHz |
| I2C SDA | P0.06 | 100 kHz |
| UART TX de diagnóstico | P0.20 | Desactivado en producción |
| LED activo en alto | P1.10 | Queda apagado durante la operación normal |
| LFCLK XL1 | XL1 | Cristal pasivo de 32.768 kHz |
| LFCLK XL2 | XL2 | Cristal pasivo de 32.768 kHz |

El esquema con un cristal conectado entre XL1 y XL2 y dos capacitores a masa
corresponde al modo `XTAL`; no debe configurarse como una entrada de oscilador
activo. La capacitancia de carga aproximada es:

```text
CL = (C1 * C2) / (C1 + C2) + capacitancia_parásita
```

Con `C1 = C2 = 20 pF`, los capacitores aportan 10 pF antes de sumar la
capacitancia parásita de pistas y pines. Se debe comprobar que el resultado
coincida con el valor `CL` indicado en la hoja de datos del cristal.

## Configuración de bajo consumo

La configuración de producción está en `prj.conf`:

```ini
CONFIG_BT_CTLR_TX_PWR_MINUS_20=y
CONFIG_CLOCK_CONTROL_NRF_K32SRC_XTAL=y
CONFIG_CLOCK_CONTROL_NRF_K32SRC_50PPM=y
CONFIG_SERIAL=n
CONFIG_CONSOLE=n
CONFIG_UART_CONSOLE=n
CONFIG_LOG=n
```

El cristal LF externo evita la calibración periódica que necesita el oscilador
RC interno y proporciona una base de tiempo estable durante el reposo. La
precisión de 50 ppm es conservadora; puede cambiarse si la hoja de datos del
cristal garantiza otro valor.

La secuencia de operación es:

1. Inicializar sensores, SAADC y BLE.
2. Medir temperatura, humedad, presión relativa y VDD.
3. Publicar varias veces la misma trama durante una ráfaga de 2 segundos.
4. Detener la publicidad y permanecer inactivo hasta completar 60 segundos.

## Trama BLE

Se usa Manufacturer Specific Data con Company ID temporal `0xFFFF`, magic
`BS`, versión `1` y Device ID `0xB1050001`. La descripción byte a byte está en
[docs/biosense_ble_frame.md](docs/biosense_ble_frame.md).

La aplicación filtra por el contenido de la trama y no por la dirección BLE,
porque Android/iOS pueden presentar identificadores diferentes y la dirección
puede cambiar.

## Compilar

Requiere nRF Connect SDK 3.4.0 y un entorno de terminal inicializado para NCS.
Desde esta carpeta:

```powershell
west build -p always -b supermini_custom/nrf52840 .
```

El archivo programable se genera en:

```text
build/zephyr/zephyr.hex
```

## Programar

Con DAPLink/CMSIS-DAP y pyOCD:

```powershell
west flash -d build -r pyocd
```

No se verá una consola UART con la configuración de producción. Para una sesión
de diagnóstico se pueden habilitar temporalmente `CONFIG_SERIAL`,
`CONFIG_CONSOLE`, `CONFIG_UART_CONSOLE` y `CONFIG_LOG`; el TX está en P0.20 a
115200 baudios.

## Puesta en marcha

Encienda el equipo sin aplicar presión al WF100DPZ. Durante el arranque el
firmware calcula su cero inicial y después descarta como cero cualquier presión
inferior a 0.10 kPa, incluidas las lecturas negativas.
