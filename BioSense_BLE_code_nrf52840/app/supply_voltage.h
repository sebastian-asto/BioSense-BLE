#ifndef BIOSENSE_SUPPLY_VOLTAGE_H_
#define BIOSENSE_SUPPLY_VOLTAGE_H_

#include <stdint.h>

/**
 * @brief Configura el SAADC para medir el VDD interno del nRF52840.
 *
 * @return 0 si esta listo, o un error negativo.
 */
int supply_voltage_init(void);

/**
 * @brief Lee el voltaje VDD del nRF52840.
 *
 * @param voltage_mv Voltaje medido en milivoltios.
 *
 * @return 0 si la lectura fue correcta, o un error negativo.
 */
int supply_voltage_sample(int32_t *voltage_mv);

#endif /* BIOSENSE_SUPPLY_VOLTAGE_H_ */
