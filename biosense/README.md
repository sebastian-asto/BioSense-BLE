# BioSense

Aplicacion Flutter que escucha la publicidad BLE del sensor BioSense sin
establecer una conexion. Muestra temperatura, humedad, presion relativa y el
voltaje VDD medido por el nRF52840.

## Identificacion BLE

La aplicacion solo acepta Manufacturer Data con:

- Company ID de desarrollo: `0xFFFF`
- Magic: `BS`
- Version: `1`
- Device ID: `0xB1050001`

La direccion BLE del sistema operativo se muestra como informacion, pero no se
usa como filtro porque puede cambiar y en iOS no representa una direccion MAC.

## Uso

1. Cargar el firmware BioSense en el nRF52840 y encenderlo sin presion aplicada
   para permitir la tara del sensor.
2. Instalar la aplicacion en un telefono fisico y aceptar el permiso Bluetooth.
3. Mantener la aplicacion abierta. El primer dato puede tardar hasta un minuto;
   los siguientes llegan cada 60 segundos.

```powershell
flutter run
```

El APK de depuracion se genera con:

```powershell
flutter build apk --debug
```
