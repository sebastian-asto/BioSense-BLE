#ifndef BIOSENSE_BLE_H_
#define BIOSENSE_BLE_H_

#include <stdint.h>

struct biosense_measurement {
	int32_t temperature_centi_c;
	int32_t humidity_centi_percent;
	int32_t pressure_centi_kpa;
	int32_t supply_voltage_mv;
};

int biosense_ble_init(void);
int biosense_ble_publish(const struct biosense_measurement *measurement);

#endif /* BIOSENSE_BLE_H_ */
