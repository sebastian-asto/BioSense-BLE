#ifndef BIOSENSE_HTU21D_MONITOR_H_
#define BIOSENSE_HTU21D_MONITOR_H_

#include <stdint.h>

struct htu21d_sample {
	int32_t temperature_centi_c;
	int32_t humidity_centi_percent;
};

/**
 * @brief Comprueba que el HTU21D definido en DeviceTree este disponible.
 *
 * @return 0 si esta listo, o un error negativo.
 */
int htu21d_monitor_init(void);

/**
 * @brief Lee la temperatura y humedad actuales.
 *
 * @return 0 si la lectura fue correcta, o un error negativo.
 */
int htu21d_monitor_sample(struct htu21d_sample *sample);

#endif /* BIOSENSE_HTU21D_MONITOR_H_ */
