extends RefCounted
class_name TurdPartnerFactory


const TURD_APK_ID: String = "turd_init"
const TURD_NICKNAME: String = "TURD"


static func create_state() -> PartnerStateData:
	var state: PartnerStateData = APKProgressionService.create_partner_state(
		TURD_APK_ID,
		TURD_NICKNAME,
		0,
		0
	)

	if state == null:
		return null

	state.integrity_state = PartnerStateData.IntegrityState.TURD
	return state
