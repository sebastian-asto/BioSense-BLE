# Trama publicitaria BLE BioSense v1

BioSense usa publicidad BLE no conectable. Cada minuto mide los sensores,
publica la trama durante 2 segundos y vuelve al modo inactivo del sistema.

El AD type es `Manufacturer Specific Data (0xFF)`. El identificador de empresa
`0xFFFF` se usa solamente durante el desarrollo y debe sustituirse por un
Company Identifier asignado antes de comercializar el producto.

Todos los enteros de varios bytes usan little-endian.

| Offset en Manufacturer Data | Tamano | Campo | Unidad |
| ---: | ---: | --- | --- |
| 0 | 2 | Company ID `0xFFFF` | - |
| 2 | 2 | Magic ASCII `BS` | - |
| 4 | 1 | Version `1` | - |
| 5 | 4 | Device ID `0xB1050001` | - |
| 9 | 2 | Numero de secuencia | - |
| 11 | 2 | Temperatura con signo | 0.01 grados C |
| 13 | 2 | Humedad sin signo | 0.01 %RH |
| 15 | 2 | Presion con signo | 0.01 kPa |
| 17 | 2 | VDD sin signo | mV |
| 19 | 1 | Flags (`bit0`: bateria baja) | - |

Flutter Blue Plus separa los dos bytes del Company ID como clave del mapa
`manufacturerData`. Por eso el decodificador Flutter recibe 18 bytes y su
offset cero corresponde al magic `BS`.
