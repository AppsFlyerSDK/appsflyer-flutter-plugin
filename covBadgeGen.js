const lcov2badge = require("lcov2badge");
const fs = require("fs");

lcov2badge.badge("./coverage/lcov.info", function (err, svgBadge) {
  if (err) throw err;

  try {
    if (fs.existsSync("./coverage_badge.svg")) {
      fs.unlinkSync("./coverage_badge.svg");
      console.log("[INFO] remove old file");
    }
  } catch (err) {
    console.error(err);
  }

  console.log("[INFO] generate coverage image");
  fs.writeFile("./coverage_badge.svg", svgBadge, (_) =>
    console.log("[INFO] complete")
  );
});