export default function () {
  this.route("lexicon-deeplink", { path: "/lexicon/deeplink/*link" });
  this.route("deeplink", { path: "/deeplink/*link" });
}
