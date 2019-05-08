const fs = require('fs');
const path = require('path');

function mkDirByPathSync(targetDir) {
  const sep = path.sep;
  const initDir = path.isAbsolute(targetDir) ? sep : '';
  const baseDir = '.';

  targetDir.split(sep).reduce((parentDir, childDir) => {
    const curDir = path.resolve(baseDir, parentDir, childDir);
    if (!fs.existsSync(curDir)) {
      try {
        fs.mkdirSync(curDir);
      } catch (err) {
        if (err.code !== 'EEXIST') {
          throw err;
        }
      }
    }

    return curDir;
  }, initDir);
}

exports.mkDirByPathSync = mkDirByPathSync
