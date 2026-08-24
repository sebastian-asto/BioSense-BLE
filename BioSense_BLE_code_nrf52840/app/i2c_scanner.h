#ifndef BIOSENSE_I2C_SCANNER_H_
#define BIOSENSE_I2C_SCANNER_H_

/**
 * @brief Escanea las direcciones I2C de 7 bits y registra las encontradas.
 *
 * @return Cantidad de dispositivos encontrados, o un error negativo.
 */
int i2c_scanner_run(void);

#endif /* BIOSENSE_I2C_SCANNER_H_ */
