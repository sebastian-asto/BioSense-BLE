#include "i2c_scanner.h"

#include <errno.h>
#include <stdint.h>

#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/drivers/i2c.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(i2c_scanner, LOG_LEVEL_INF);

#define I2C_SCAN_FIRST_ADDRESS 0x08
#define I2C_SCAN_LAST_ADDRESS  0x77

static const struct device *const i2c_bus = DEVICE_DT_GET(DT_NODELABEL(i2c0));

static int i2c_probe_address(uint8_t address)
{
	uint8_t dummy;
	struct i2c_msg message = {
		.buf = &dummy,
		.len = 0U,
		.flags = I2C_MSG_WRITE | I2C_MSG_STOP,
	};

	return i2c_transfer(i2c_bus, &message, 1, address);
}

int i2c_scanner_run(void)
{
	uint8_t devices_found = 0U;

	if (!device_is_ready(i2c_bus)) {
		LOG_ERR("El controlador I2C0 no esta listo");
		return -ENODEV;
	}

	LOG_INF("Escaneando I2C0: SCL=P0.26, SDA=P0.06, 100 kHz");

	for (uint16_t address = I2C_SCAN_FIRST_ADDRESS;
	     address <= I2C_SCAN_LAST_ADDRESS;
	     address++) {
		if (i2c_probe_address((uint8_t)address) == 0) {
			LOG_INF("Dispositivo I2C encontrado en 0x%02X", address);
			devices_found++;
		}
	}

	if (devices_found == 0U) {
		LOG_WRN("No se encontraron dispositivos I2C");
	} else {
		LOG_INF("Escaneo terminado: %u dispositivo(s) encontrado(s)",
			devices_found);
	}

	return devices_found;
}
