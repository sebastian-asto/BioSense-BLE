#ifndef BIOSENSE_WF100DPZ_H_
#define BIOSENSE_WF100DPZ_H_

#include <stdint.h>

/**
 * @brief Comprueba el WF100DPZ y calibra su cero a presion ambiente.
 *
 * El puerto debe estar libre de presion durante la inicializacion.
 *
 * @return 0 si esta listo, o un error negativo.
 */
int wf100dpz_init(void);

/**
 * @brief Ejecuta una conversion y obtiene la presion relativa.
 *
 * @param pressure_centi_kpa Presion en centesimas de kPa.
 *
 * @return 0 si la lectura fue correcta, o un error negativo.
 */
int wf100dpz_sample_pressure(int32_t *pressure_centi_kpa);

#endif /* BIOSENSE_WF100DPZ_H_ */
