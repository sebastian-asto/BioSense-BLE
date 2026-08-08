# nRF52840 Blinky con DAPLink

Proyecto de prueba para compilar y programar una placa **SuperMini nRF52840**
mediante SWD usando nRF Connect SDK y Zephyr.

## Hardware utilizado

- SoC: Nordic Semiconductor nRF52840.
- Placa: SuperMini/Pro Micro nRF52840.
- Board target de Zephyr: `promicro_nrf52840/nrf52840`.
- Programador: WeAct Studio Mini Debugger con firmware **DAPLink/CMSIS-DAP**.
- Runner de programación: `pyocd`.
- LED de usuario: `LED0`, conectado a `P0.15` y definido por Devicetree.

> El Mini Debugger debe estar funcionando en modo DAPLink, no en modo
> ST-Link, para utilizarlo con el runner `pyocd`.

## Conexión SWD

| DAPLink | SuperMini nRF52840 |
|---|---|
| SWDIO | DIO |
| SWCLK | CLK |
| GND | GND |
| VTref / 3.3 V | VDD |
| NRST (opcional) | RST |

No conectar 5 V, `RAW` ni `B+` a la interfaz SWD. Si la placa se alimenta
desde su USB-C, `VDD` se utiliza como referencia del nivel lógico del
programador.

## Compilar

Los siguientes comandos se ejecutan desde el directorio de la aplicación:

```powershell
cd blink_nrf
west build -p always -b promicro_nrf52840/nrf52840 .
```

El firmware generado se encuentra en:

```text
blink_nrf/build/blink_nrf/zephyr/zephyr.hex
```

## Programar mediante DAPLink

```powershell
west flash -d build -r pyocd
```

Es necesario indicar `-r pyocd` porque la board utiliza J-Link como runner
predeterminado. Sin esa opción, `west flash` intentará abrir `JLink.exe` y
fallará si el programador conectado es DAPLink.

Una programación correcta muestra una salida similar a:

```text
-- west flash: using runner pyocd
-- runners.pyocd: Flashing file: .../zephyr/zephyr.hex
[==================================================] 100%
```

## Resultado

El ejemplo obtiene el LED a través del alias `led0` de Devicetree y conmuta
su estado cada 100 ms. Después de programar y reiniciar el nRF52840, el LED
integrado comienza a parpadear.
