#include "htu21d_monitor.h"

#include <errno.h>
#include <stdint.h>

#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/drivers/sensor.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(htu21d_monitor, LOG_LEVEL_INF);

static const struct device *const htu21d =
	DEVICE_DT_GET(DT_NODELABEL(htu21d));

int htu21d_monitor_init(void)
{
	if (!device_is_ready(htu21d)) {
		LOG_ERR("El sensor HTU21D en 0x40 no esta listo");
		return -ENODEV;
	}

	return 0;
}

int htu21d_monitor_sample(struct htu21d_sample *sample)
{
	struct sensor_value temperature;
	struct sensor_value humidity;
	int error;

	if (sample == NULL) {
		return -EINVAL;
	}

	error = sensor_sample_fetch(htu21d);
	if (error < 0) {
		LOG_ERR("No se pudo leer el HTU21D (error %d)", error);
		return error;
	}

	error = sensor_channel_get(htu21d, SENSOR_CHAN_AMBIENT_TEMP,
				   &temperature);
	if (error < 0) {
		LOG_ERR("No se pudo obtener la temperatura (error %d)", error);
		return error;
	}

	error = sensor_channel_get(htu21d, SENSOR_CHAN_HUMIDITY, &humidity);
	if (error < 0) {
		LOG_ERR("No se pudo obtener la humedad (error %d)", error);
		return error;
	}

	sample->temperature_centi_c =
		(int32_t)sensor_value_to_centi(&temperature);
	sample->humidity_centi_percent =
		(int32_t)sensor_value_to_centi(&humidity);

	return 0;
}
