import { action } from "@ember/object";
import { service } from "@ember/service";
import DiscourseURL from "discourse/lib/url";
import DiscourseRoute from "discourse/routes/discourse";

export default class DeeplinkRoute extends DiscourseRoute {
  is_pm = false;
  redirect_to_app = false;

  @service router;

  beforeModel(params) {
    this.is_pm = (params.to.queryParams.is_pm ?? "false") === "true";
    this.redirect_to_app = params.to.queryParams.is_pm === undefined;
  }

  model({ link }) {
    const isAndroid = navigator.userAgent.match(/Android/i);

    // `iOS` allows us to programmatically open links without user interaction
    // Android sometimes causes issues. Only attempt to open it automatically
    // if we're not on Android.
    if (!isAndroid || !this.siteSettings.lexicon_app_scheme) {
      this.open(link);
    }

    return { link, is_pm: this.is_pm, redirect_to_app: this.redirect_to_app };
  }

  @action
  open(link) {
    const isMobile = navigator.userAgent.match(/(iPad|iPhone|iPod|Android)/g);
    if (this.siteSettings.lexicon_app_scheme && isMobile) {
      // Using `DiscourseURL.redirectTo` allows us to mock this in tests
      // Additionally, Discourse won't actually call it in tests since, according
      // to them, that kills the test runner.
      // Internally, this uses `window.location = url` rather than `window.location.replace`.
      if (
        this.siteSettings.lexicon_activate_account_link_enabled &&
        link.startsWith("u/activate-account/")
      ) {
        const [, , emailToken] = link.split("/");
        DiscourseURL.redirectTo(
          `${this.siteSettings.lexicon_app_scheme}://activate-account/${emailToken}`
        );
      } else if (
        this.siteSettings.lexicon_login_link_enabled &&
        link.startsWith("session/email-login/")
      ) {
        const [, , emailToken] = link.split("/");
        DiscourseURL.redirectTo(
          `${this.siteSettings.lexicon_app_scheme}://email-login/${emailToken}`
        );
      } else {
        const scene = this.is_pm ? "message-detail" : "post-detail";
        DiscourseURL.redirectTo(
          `${this.siteSettings.lexicon_app_scheme}://${scene}/${link}`
        );
      }
    }
    this.router.transitionTo(`/${link}`);
  }
}
