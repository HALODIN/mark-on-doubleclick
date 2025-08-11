
// SPDX-License-Identifier: MIT
// Evolution EPlugin v4.5: "Mark on Double-Click"
// - No Configuration/Accounts UI (Owner tab only).
// - Core behavior: keep preview Unread; mark Read on double-click (message-loaded).
// - Still supports enable/disable via Plugin Manager checkbox.

#include <glib.h>
#include <gmodule.h>
#include <gtk/gtk.h>
#include <e-util/e-util.h>
#include <mail/e-mail-reader.h>
#include <mail/e-mail-browser.h>
#include <mail/e-mail-paned-view.h>
#include <camel/camel.h>

#define PLUGIN_NAME  "Mark on Double-Click"
#define PLUGIN_ID    "org.gnome.mark-on-doubleclick"
#define AUTHOR_EMAIL "craigh@funktion.net"

typedef struct {
    gboolean enabled;
    gboolean suppress_preview;
    guint    delay_ms;
} ModcSettings;

static void settings_default (ModcSettings *s) {
    s->enabled = TRUE;
    s->suppress_preview = TRUE;
    s->delay_ms = 0;
}

static ModcSettings GSETTINGS;
static gulong g_emission_hook_id = 0;

/* Mark seen with optional delay */
typedef struct { GWeakRef reader_ref; guint delay_ms; } DelayCtx;
static gboolean delayed_mark_cb (gpointer data) {
    DelayCtx *ctx = data;
    EMailReader *reader = g_weak_ref_get (&ctx->reader_ref);
    if (reader) { e_mail_reader_mark_selected (reader, CAMEL_MESSAGE_SEEN, CAMEL_MESSAGE_SEEN); g_object_unref (reader); }
    g_weak_ref_clear (&ctx->reader_ref);
    g_free (ctx);
    return G_SOURCE_REMOVE;
}
static void mark_seen (EMailReader *reader) {
    if (GSETTINGS.delay_ms == 0) {
        e_mail_reader_mark_selected (reader, CAMEL_MESSAGE_SEEN, CAMEL_MESSAGE_SEEN);
    } else {
        DelayCtx *ctx = g_new0 (DelayCtx, 1);
        g_weak_ref_init (&ctx->reader_ref, reader);
        ctx->delay_ms = GSETTINGS.delay_ms;
        g_timeout_add_full (G_PRIORITY_DEFAULT, ctx->delay_ms, delayed_mark_cb, ctx, NULL);
    }
}

/* Emission hook */
static gboolean on_message_loaded_emission (GSignalInvocationHint *hint, guint n_param_values, const GValue *vals, gpointer user_data) {
    if (!GSETTINGS.enabled) return TRUE;
    gpointer instance = g_value_get_object (&vals[0]);
    if (!instance) return TRUE;
    if (E_IS_MAIL_BROWSER (instance)) {
        mark_seen (E_MAIL_READER (instance));
    } else if (E_IS_MAIL_PANED_VIEW (instance)) {
        if (GSETTINGS.suppress_preview) e_mail_reader_avoid_next_mark_as_seen (E_MAIL_READER (instance));
    }
    return TRUE;
}

/* Load-time: install hook */
G_MODULE_EXPORT gboolean e_plugin_ui_init (GtkUIManager *ui_manager, gpointer user_data)
{
    static gboolean installed = FALSE;
    if (installed) return TRUE;
    settings_default (&GSETTINGS);

    guint sig = g_signal_lookup ("message-loaded", E_TYPE_MAIL_READER);
    if (sig) {
        g_emission_hook_id = g_signal_add_emission_hook (sig, 0, on_message_loaded_emission, NULL, NULL);
        g_message ("[%s] Emission hook installed.", PLUGIN_NAME);
    }
    installed = TRUE;
    return TRUE;
}

/* Enable/disable checkbox from Plugin Manager */
G_MODULE_EXPORT gint e_plugin_lib_enable (EPlugin *ep, gint enable)
{
    GSETTINGS.enabled = enable ? TRUE : FALSE;
    return 0;
}
