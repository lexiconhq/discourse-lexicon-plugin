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
    this.email_token = params.to.queryParams.t;
  }

  model({ link }) {
    const isAndroid = navigator.userAgent.match(/Android/i);

    // `iOS` allows us to programmatically open links without user interaction
    // Android sometimes causes issues. Only attempt to open it automatically
    // if we're not on Android.

    if (!isAndroid || !this.siteSettings.lexicon_app_scheme) {
      this.open(link);
    }

    return {
      link,
      is_pm: this.is_pm,
      redirect_to_app: this.redirect_to_app,
      email_token: this.email_token,
    };
  }

  @action
  open(link) {
    const isMobile = navigator.userAgent.match(/(iPad|iPhone|iPod|Android)/g);

    if (this.siteSettings.lexicon_app_scheme && isMobile) {
      // Using `DiscourseURL.redirectTo` allows us to mock this in tests
      // Additionally, Discourse won't actually call it in tests since, according
      // to them, that kills the test runner.
      // Internally, this uses `window.location = url` rather than `window.location.replace`.

      const hostname = window.location.hostname;
      if (link.startsWith("u/activate-account/")) {
        // NOTE: We are disabling activate-account deeplinks for now but keeping the code for future reference
        // const [, , emailToken] = link.split("/");
        // DiscourseURL.redirectTo(
        //   `${this.siteSettings.lexicon_app_scheme}://${hostname}/activate-account/${emailToken}`
        // );
        return;
      } else if (
        // NOTE: activate-account deeplinks will be disabled but the login deeplinks will still work
        this.siteSettings.lexicon_activate_account_link_enabled &&
        link.startsWith("login")
      ) {
        DiscourseURL.redirectTo(
          `${this.siteSettings.lexicon_app_scheme}://${hostname}/login`,
        );
      } else if (
        this.siteSettings.lexicon_invites_link_enabled &&
        link.startsWith("invites/")
      ) {
        // invites format will be invites/{token}
        const [, inviteKey] = link.split("/");

        const deeplink = this.email_token
          ? `invites/${inviteKey}?t=${this.email_token}`
          : `invites/${inviteKey}`;

        DiscourseURL.redirectTo(
          `${this.siteSettings.lexicon_app_scheme}://${hostname}/${deeplink}`,
        );
      } else {
        const scene = this.is_pm ? "message-detail" : "post-detail";
        DiscourseURL.redirectTo(
          `${this.siteSettings.lexicon_app_scheme}://${hostname}/${scene}/${link}`,
        );
      }
    }

    if (link.startsWith("invites/")) {
      const url = this.email_token
        ? `/${link}?t=${this.email_token}`
        : `/${link}`;
      setTimeout(() => {
        window.location.href = url;
      }, 500);
    } else {
      this.router.transitionTo(`/${link}`);
    }
  }
}
