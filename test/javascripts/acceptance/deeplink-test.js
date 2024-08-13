import sinon from "sinon";
import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { currentURL, visit } from "@ember/test-helpers";
import I18n from "I18n";

import DiscourseURL from "discourse/lib/url";

const topicId = 15;
const postId = 1;
const slug = "hello";
const appScheme = "lexicon";

const deepLinkUrl = `/lexicon/deeplink/t/${slug}/${topicId}/${postId}`;

let json = `{
  "posts": [
    {
      "id": ${postId},
      "cooked": "<p>Hello. Hello there. Hello</p>",
      "topic_id": ${topicId},
      "topic_slug": "${slug}",
      "user_id": 1,
    }
  ],
}`;

acceptance("Email Deep Linking Plugin", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get(`/t/${topicId}/${postId}.json`, () => helper.response(json));
  });

  needs.settings({ lexicon_app_scheme: appScheme });

  test("plugin redirects correctly on desktop web", async function (assert) {
    await visit(`${deepLinkUrl}?is_pm=true`);

    assert.strictEqual(
      currentURL(),
      `/t/${slug}/${topicId}/${postId}`,
      "should route to the message page"
    );
  });

  test("attempts to automatically open the app on iPhone", async function (assert) {
    // Our implementation in `deeplink.js.es6` doesn't currently use Discourse's
    // concept of `mobileView`, so there's no benefit to leveraging `needs.mobileView()` here.
    // Instead, the implementation checks the `userAgent` directly, so that's what we stub
    // here with `sinon`.
    sinon.stub(window.navigator, "userAgent").get(() => "iPhone");

    const stub = sinon
      .stub(DiscourseURL, "redirectTo")
      .callsFake((url) =>
        assert.equal(
          url,
          `${appScheme}://post-detail/t/${slug}/${topicId}/${postId}`
        )
      );

    await visit(deepLinkUrl);
    assert.true(stub.called, "DiscourseURL.redirectTo mock must be called");
  });

  // There is probably a better way to do this by grouping tests; feel free to improve.
  const useAndroidFlow = (queryParams = {}) => {
    sinon.stub(window.navigator, "userAgent").get(() => "Android");
    const { isPm = false } = queryParams;
    let url = `${deepLinkUrl}?is_pm=${isPm}`;

    return visit(url);
  };

  test("button reads 'View Post' when notification is for a post", async function (assert) {
    await useAndroidFlow({ isPm: false });

    const button = query("#open-in-lexicon-app");
    assert.equal(button?.innerText, I18n.t("deeplink.button_label_view_post"));
  });

  test("button reads 'View Message' when notification is for a message", async function (assert) {
    await useAndroidFlow({ isPm: true });

    const button = query("#open-in-lexicon-app");
    assert.equal(
      button?.innerText,
      I18n.t("deeplink.button_label_view_message")
    );
  });
});
