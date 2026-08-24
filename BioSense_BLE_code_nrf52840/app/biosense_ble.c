#include "biosense_ble.h"

#include <errno.h>
#include <stdint.h>

#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/gap.h>
#include <zephyr/kernel.h>
#include <zephyr/sys/byteorder.h>
#include <zephyr/sys/util.h>

#define BIOSENSE_COMPANY_ID 0xFFFFU
#define BIOSENSE_DEVICE_ID  0xB1050001U
#define BIOSENSE_FRAME_VERSION 1U

#define BIOSENSE_MANUFACTURER_DATA_SIZE 20U
#define BIOSENSE_FRAME_OFFSET_DEVICE_ID 5U
#define BIOSENSE_FRAME_OFFSET_SEQUENCE 9U
#define BIOSENSE_FRAME_OFFSET_TEMPERATURE 11U
#define BIOSENSE_FRAME_OFFSET_HUMIDITY 13U
#define BIOSENSE_FRAME_OFFSET_PRESSURE 15U
#define BIOSENSE_FRAME_OFFSET_VOLTAGE 17U
#define BIOSENSE_FRAME_OFFSET_FLAGS 19U

#define BIOSENSE_FLAG_LOW_BATTERY BIT(0)
#define BIOSENSE_LOW_BATTERY_MV 2400
#define BIOSENSE_ADVERTISING_BURST_MS 2000

BUILD_ASSERT((2U + 1U) + (2U + BIOSENSE_MANUFACTURER_DATA_SIZE) +
	     (2U + 2U) <= 31U,
	     "La trama BioSense no cabe en publicidad BLE legacy");

static uint8_t manufacturer_data[BIOSENSE_MANUFACTURER_DATA_SIZE] = {
	BIOSENSE_COMPANY_ID & 0xFFU,
	(BIOSENSE_COMPANY_ID >> 8) & 0xFFU,
	'B', 'S',
	BIOSENSE_FRAME_VERSION,
};
static uint16_t sequence_number;

static const struct bt_data advertising_data[] = {
	BT_DATA_BYTES(BT_DATA_FLAGS, BT_LE_AD_NO_BREDR),
	BT_DATA(BT_DATA_MANUFACTURER_DATA, manufacturer_data,
		BIOSENSE_MANUFACTURER_DATA_SIZE),
	BT_DATA_BYTES(BT_DATA_NAME_SHORTENED, 'B', 'S'),
};

static const struct bt_le_adv_param advertising_parameters =
	BT_LE_ADV_PARAM_INIT(BT_LE_ADV_OPT_USE_IDENTITY,
			     BT_GAP_ADV_FAST_INT_MIN_2,
			     BT_GAP_ADV_FAST_INT_MAX_2, NULL);

static int16_t clamp_i16(int32_t value)
{
	return (int16_t)CLAMP(value, INT16_MIN, INT16_MAX);
}

static uint16_t clamp_u16(int32_t value)
{
	return (uint16_t)CLAMP(value, 0, UINT16_MAX);
}

int biosense_ble_init(void)
{
	return bt_enable(NULL);
}

int biosense_ble_publish(const struct biosense_measurement *measurement)
{
	uint8_t flags = 0U;
	int error;

	if (measurement == NULL) {
		return -EINVAL;
	}

	sys_put_le32(BIOSENSE_DEVICE_ID,
		     &manufacturer_data[BIOSENSE_FRAME_OFFSET_DEVICE_ID]);
	sys_put_le16(sequence_number,
		     &manufacturer_data[BIOSENSE_FRAME_OFFSET_SEQUENCE]);
	sys_put_le16((uint16_t)clamp_i16(measurement->temperature_centi_c),
		     &manufacturer_data[BIOSENSE_FRAME_OFFSET_TEMPERATURE]);
	sys_put_le16(clamp_u16(measurement->humidity_centi_percent),
		     &manufacturer_data[BIOSENSE_FRAME_OFFSET_HUMIDITY]);
	sys_put_le16((uint16_t)clamp_i16(measurement->pressure_centi_kpa),
		     &manufacturer_data[BIOSENSE_FRAME_OFFSET_PRESSURE]);
	sys_put_le16(clamp_u16(measurement->supply_voltage_mv),
		     &manufacturer_data[BIOSENSE_FRAME_OFFSET_VOLTAGE]);

	if (measurement->supply_voltage_mv < BIOSENSE_LOW_BATTERY_MV) {
		flags |= BIOSENSE_FLAG_LOW_BATTERY;
	}
	manufacturer_data[BIOSENSE_FRAME_OFFSET_FLAGS] = flags;

	error = bt_le_adv_start(&advertising_parameters, advertising_data,
				ARRAY_SIZE(advertising_data), NULL, 0);
	if (error < 0) {
		return error;
	}

	k_msleep(BIOSENSE_ADVERTISING_BURST_MS);

	error = bt_le_adv_stop();
	if (error < 0) {
		return error;
	}

	sequence_number++;
	return 0;
}
