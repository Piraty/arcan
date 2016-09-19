/*
 * simple skeleton for using TUI, useful as template to
 * only have to deal with a minimum of boilerplate
 */
#include <arcan_shmif.h>
#include <arcan_shmif_tui.h>
#include <inttypes.h>

static inline void trace(const char* msg, ...)
{
#ifdef TRACE_ENABLE
	va_list args;
	va_start( args, msg );
		vfprintf(stderr,  msg, args );
	va_end( args);
	fprintf(stderr, "\n");
#endif
}

static void on_label(struct tui_context* c, const char* label, void* t)
{
	trace("label(%s)", label);
}

static void on_mouse(struct tui_context* c,
	bool relative, int x, int y, uint16_t button_mask, void* t)
{
	trace("mouse(%d:%d, mask:%"PRIu16", rel: %d",
		x, y, button_mask, (int) relative);
}

static void on_key(struct tui_context* c, bool active,
	uint32_t xkeysym, uint32_t ucs4, uint16_t subid)
{
	trace("unknown_key(%"PRIu32",%"PRIu32",%"PRIu16")", xkeysym, ucs4, subid);
}

static void on_u8(struct tui_context* c, const char* u8, size_t len, void* t)
{
	uint8_t buf[5] = {0};
	memcpy(buf, u8, len >= 5 ? 4 : len);
	trace("utf8-input: %s", buf);
}

static void on_misc(struct tui_context* c, const arcan_ioevent* ev, void* t)
{
	trace("on_ioevent()");
}

static void on_state(struct tui_context* c, bool input, int fd, void* t)
{
	trace("on-state(in:%d)", (int)input);
}

static void on_bchunk(struct tui_context* c,
	bool input, uint64_t size, int fd, void* t)
{
	trace("on_bchunk(%"PRIu64", in:%d)", size, (int)input);
}

static void on_vpaste(struct tui_context* c,
		shmif_pixel* vidp, size_t w, size_t h, size_t stride, void* t)
{
	trace("on_vpaste(%zu, %zu str %zu)", w, h, stride);
}

static void on_apaste(struct tui_context* c,
	shmif_asample* audp, size_t n_samples, size_t frequency, size_t nch, void* t)
{
	trace("on_apaste(%zu @ %zu:%zu)", n_samples, frequency, nch);
}

static void on_raw(struct tui_context* c, arcan_event* ev, void* t)
{
	trace("on-raw(%s)", arcan_shmif_eventstr(ev, NULL, 0));
}

static void on_tick(struct tui_context* c, void* t)
{
	trace("[tick]");
}

static void on_utf8_paste(struct tui_context* c,
	const uint8_t* str, size_t len, bool cont, void* t)
{
	trace("utf8-paste(%s):%d", str, (int) cont);
}

static void on_resize(struct tui_context* c,
	size_t neww, size_t newh, size_t col, size_t row, void* t)
{
	trace("resize(%zu(%zu),%zu(%zu))", neww, col, newh, row);
}

int main(int argc, char** argv)
{
	struct arg_arr* aarr;
	struct arcan_shmif_cont con = arcan_shmif_open(
		SEGID_TERMINAL, SHMIF_ACQUIRE_FATALFAIL, &aarr);

/*
 * only the ones that are relevant needs to be filled
 */
	struct tui_cbcfg cbcfg = {
		.input_label = on_label,
		.input_mouse = on_mouse,
		.input_utf8 = on_u8,
		.input_key = on_key,
		.input_misc = on_misc,
		.state = on_state,
		.bchunk = on_bchunk,
		.vpaste = on_vpaste,
		.apaste = on_apaste,
		.raw_event = on_raw,
		.tick = on_tick,
		.utf8 = on_utf8_paste,
		.resized = on_resize
	};

/* even though we handle over management of con to TUI, we can
 * still get access to its internal reference at will */
	struct tui_settings cfg = arcan_tui_defaults();
	arcan_tui_apply_arg(&cfg, aarr);
	struct tui_context* tui = arcan_tui_setup(&con, &cfg, &cbcfg);

	if (!tui){
		fprintf(stderr, "failed to setup TUI connection\n");
		return EXIT_FAILURE;
	}

/*
 * it is also possible to handle multiple- TUI connections in one
 * loop, and add own descriptors to monitor (then the return value
 * needs to be checked for data or be closed down
 */
	while (1){
		int errc = 0;
		arcan_tui_process(&tui, 1, NULL, 0, -1, &errc);
		if (errc != TUI_ERRC_OK)
			break;
	}

	arcan_tui_destroy(tui);

	return EXIT_SUCCESS;
}