#include <stdint.h>

#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>

#include "biosense_ble.h"
#include "htu21d_monitor.h"
#include "supply_voltage.h"
#include "wf100dpz.h"

#define MEASUREMENT_INTERVAL_MS 60000
#define PRESSURE_DISPLAY_THRESHOLD_CENTI_KPA 10
#define LED0_NODE DT_ALIAS(led0)

#if !DT_NODE_HAS_STATUS(LED0_NODE, okay)
#error "La board debe definir el alias led0"
#endif

static const struct gpio_dt_spec led = GPIO_DT_SPEC_GET(LED0_NODE, gpios);

static int sample_environment(struct biosense_measurement *measurement)
{
	struct htu21d_sample climate;
	int error;

	error = htu21d_monitor_sample(&climate);
	if (error < 0) {
		return error;
	}

	error = wf100dpz_sample_pressure(&measurement->pressure_centi_kpa);
	if (error < 0) {
		return error;
	}

	error = supply_voltage_sample(&measurement->supply_voltage_mv);
	if (error < 0) {
		return error;
	}

	measurement->temperature_centi_c = climate.temperature_centi_c;
	measurement->humidity_centi_percent = climate.humidity_centi_percent;

	/* Oculta pequenas variaciones de cero y todas las lecturas negativas. */
	if (measurement->pressure_centi_kpa <
	    PRESSURE_DISPLAY_THRESHOLD_CENTI_KPA) {
		measurement->pressure_centi_kpa = 0;
	}

	return 0;
}

int main(void)
{
	struct biosense_measurement measurement;
	int64_t next_measurement_ms;
	int64_t remaining_ms;
	int error;

	if (!gpio_is_ready_dt(&led)) {
		return 0;
	}

	error = gpio_pin_configure_dt(&led, GPIO_OUTPUT_INACTIVE);
	if (error < 0) {
		return 0;
	}

	/* Permite que los sensores terminen su encendido antes de la tara. */
	k_msleep(100);
	if (htu21d_monitor_init() < 0 || wf100dpz_init() < 0 ||
	    supply_voltage_init() < 0 || biosense_ble_init() < 0) {
		return 0;
	}

	next_measurement_ms = k_uptime_get();

	while (1) {
		if (sample_environment(&measurement) == 0) {
			(void)biosense_ble_publish(&measurement);
		}

		next_measurement_ms += MEASUREMENT_INTERVAL_MS;
		remaining_ms = next_measurement_ms - k_uptime_get();
		if (remaining_ms > 0) {
			k_msleep((int32_t)remaining_ms);
		} else {
			next_measurement_ms = k_uptime_get();
		}
	}

	return 0;
}
