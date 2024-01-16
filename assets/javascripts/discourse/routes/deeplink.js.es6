import { action } from "@ember/object";
import { service } from "@ember/service";
import DiscourseURL from "discourse/lib/url";
import DiscourseRoute from "discourse/routes/discourse";

export default class DeeplinkRoute extends DiscourseRoute {
  is_pm = false;

  @service router;

  beforeModel(params) {
    this.is_pm = (params.to.queryParams.is_pm ?? "false") === "true";
  }

  model({ link }) {
    const isAndroid = navigator.userAgent.match(/Android/i);

    // `iOS` allows us to programmatically open links without user interaction
    // Android sometimes causes issues. Only attempt to open it automatically
    // if we're not on Android.
    if (!isAndroid || !this.siteSettings.lexicon_app_scheme) {
      this.open(link);
    }

    return { link, is_pm: this.is_pm };
  }

  @action
  open(link) {
    const isMobile = navigator.userAgent.match(/(iPad|iPhone|iPod|Android)/g);
    const scene = this.is_pm ? "message-detail" : "post-detail";
    if (this.siteSettings.lexicon_app_scheme && isMobile) {
      // Using `DiscourseURL.redirectTo` allows us to mock this in tests
      // Additionally, Discourse won't actually call it in tests since, according
      // to them, that kills the test runner.
      // Internally, this uses `window.location = url` rather than `window.location.replace`.
      DiscourseURL.redirectTo(
        `${this.siteSettings.lexicon_app_scheme}://${scene}/${link}`
      );
    }
    this.router.transitionTo(`/${link}`);
  }
}
