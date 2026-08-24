#include "wf100dpz.h"

#include <errno.h>
#include <stdbool.h>
#include <stdint.h>

#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/drivers/i2c.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(wf100dpz, LOG_LEVEL_INF);

#define WF100DPZ_NODE DT_NODELABEL(wf100dpz)

#if !DT_NODE_HAS_STATUS(WF100DPZ_NODE, okay)
#error "DeviceTree debe definir el nodo wf100dpz"
#endif

#define WF100DPZ_REG_PART_ID  0x01
#define WF100DPZ_REG_STATUS   0x02
#define WF100DPZ_REG_PRESSURE 0x06
#define WF100DPZ_REG_COMMAND  0x30

#define WF100DPZ_STATUS_DATA_READY 0x01
#define WF100DPZ_COMMAND_PRESSURE_AND_TEMPERATURE 0x0A
#define WF100DPZ_CONVERSION_TIMEOUT_MS 20
#define WF100DPZ_ZERO_SAMPLES 8

/*
 * Escala del modelo 0.1BG (-10 a +10 kPa). El rango util ocupa el 80 %
 * de la salida normalizada, por eso la pendiente es 12.5 kPa. La tara de
 * arranque elimina el offset individual del sensor.
 */
#define WF100DPZ_RAW_FULL_SCALE       8388608LL
#define WF100DPZ_SCALE_CENTI_KPA      1250LL

static const struct i2c_dt_spec wf100dpz =
	I2C_DT_SPEC_GET(WF100DPZ_NODE);
static int32_t zero_raw_pressure;

static int wf100dpz_read_raw_pressure(int32_t *raw_pressure)
{
	uint8_t pressure_bytes[3];
	uint8_t status;
	bool data_ready = false;
	int error;

	error = i2c_reg_write_byte_dt(
		&wf100dpz, WF100DPZ_REG_COMMAND,
		WF100DPZ_COMMAND_PRESSURE_AND_TEMPERATURE);
	if (error < 0) {
		LOG_ERR("No se pudo iniciar la medicion de presion (error %d)",
			error);
		return error;
	}

	for (int elapsed_ms = 0;
	     elapsed_ms < WF100DPZ_CONVERSION_TIMEOUT_MS; elapsed_ms++) {
		error = i2c_reg_read_byte_dt(&wf100dpz, WF100DPZ_REG_STATUS,
					     &status);
		if (error < 0) {
			LOG_ERR("No se pudo leer el estado del WF100DPZ (error %d)",
				error);
			return error;
		}

		if ((status & WF100DPZ_STATUS_DATA_READY) != 0U) {
			data_ready = true;
			break;
		}

		k_msleep(1);
	}

	if (!data_ready) {
		LOG_ERR("Tiempo de espera agotado leyendo el WF100DPZ");
		return -ETIMEDOUT;
	}

	error = i2c_burst_read_dt(&wf100dpz, WF100DPZ_REG_PRESSURE,
				  pressure_bytes, sizeof(pressure_bytes));
	if (error < 0) {
		LOG_ERR("No se pudo leer la presion (error %d)", error);
		return error;
	}

	*raw_pressure = ((int32_t)pressure_bytes[0] << 16) |
			((int32_t)pressure_bytes[1] << 8) |
			(int32_t)pressure_bytes[2];
	if ((*raw_pressure & 0x00800000) != 0) {
		*raw_pressure -= 0x01000000;
	}

	return 0;
}

int wf100dpz_init(void)
{
	int64_t zero_sum = 0;
	int32_t raw_pressure;
	uint8_t part_id;
	int error;

	if (!device_is_ready(wf100dpz.bus)) {
		LOG_ERR("El bus I2C del WF100DPZ no esta listo");
		return -ENODEV;
	}

	error = i2c_reg_read_byte_dt(&wf100dpz, WF100DPZ_REG_PART_ID,
				     &part_id);
	if (error < 0) {
		LOG_ERR("El WF100DPZ en 0x6D no responde (error %d)", error);
		return error;
	}

	/* El puerto debe permanecer a presion ambiente durante esta tara. */
	for (int sample = 0; sample < WF100DPZ_ZERO_SAMPLES; sample++) {
		error = wf100dpz_read_raw_pressure(&raw_pressure);
		if (error < 0) {
			return error;
		}

		zero_sum += raw_pressure;
	}

	zero_raw_pressure = (int32_t)(zero_sum / WF100DPZ_ZERO_SAMPLES);

	return 0;
}

int wf100dpz_sample_pressure(int32_t *pressure_centi_kpa)
{
	int32_t raw_pressure;
	int64_t scaled_pressure;
	int error;

	if (pressure_centi_kpa == NULL) {
		return -EINVAL;
	}

	error = wf100dpz_read_raw_pressure(&raw_pressure);
	if (error < 0) {
		return error;
	}

	scaled_pressure = (int64_t)(raw_pressure - zero_raw_pressure) *
			  WF100DPZ_SCALE_CENTI_KPA;
	if (scaled_pressure >= 0) {
		scaled_pressure += WF100DPZ_RAW_FULL_SCALE / 2;
	} else {
		scaled_pressure -= WF100DPZ_RAW_FULL_SCALE / 2;
	}

	*pressure_centi_kpa =
		(int32_t)(scaled_pressure / WF100DPZ_RAW_FULL_SCALE);

	return 0;
}
