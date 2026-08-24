#include "supply_voltage.h"

#include <errno.h>
#include <stdint.h>

#include <zephyr/devicetree.h>
#include <zephyr/drivers/adc.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(supply_voltage, LOG_LEVEL_INF);

#define SUPPLY_ADC_NODE DT_PATH(zephyr_user)

#if !DT_NODE_EXISTS(SUPPLY_ADC_NODE) || \
	!DT_NODE_HAS_PROP(SUPPLY_ADC_NODE, io_channels)
#error "DeviceTree debe definir zephyr,user con io-channels para VDD"
#endif

static const struct adc_dt_spec supply_adc =
	ADC_DT_SPEC_GET_BY_IDX(SUPPLY_ADC_NODE, 0);

int supply_voltage_init(void)
{
	int error;

	if (!adc_is_ready_dt(&supply_adc)) {
		LOG_ERR("El SAADC para medir VDD no esta listo");
		return -ENODEV;
	}

	error = adc_channel_setup_dt(&supply_adc);
	if (error < 0) {
		LOG_ERR("No se pudo configurar el canal VDD (error %d)", error);
		return error;
	}

	return 0;
}

int supply_voltage_sample(int32_t *voltage_mv)
{
	int16_t raw_sample;
	struct adc_sequence sequence = {
		.buffer = &raw_sample,
		.buffer_size = sizeof(raw_sample),
	};
	int error;

	if (voltage_mv == NULL) {
		return -EINVAL;
	}

	error = adc_sequence_init_dt(&supply_adc, &sequence);
	if (error < 0) {
		LOG_ERR("No se pudo preparar la lectura de VDD (error %d)", error);
		return error;
	}

	error = adc_read_dt(&supply_adc, &sequence);
	if (error < 0) {
		LOG_ERR("No se pudo leer VDD (error %d)", error);
		return error;
	}

	*voltage_mv = raw_sample;
	error = adc_raw_to_millivolts_dt(&supply_adc, voltage_mv);
	if (error < 0) {
		LOG_ERR("No se pudo convertir VDD a milivoltios (error %d)",
			error);
		return error;
	}

	return 0;
}
