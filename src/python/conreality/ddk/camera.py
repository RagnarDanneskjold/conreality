# This is free and unencumbered software released into the public domain.

"""Camera support."""

from ..sdk.vision import SharedImage
from ..sdk.storage import DataDirectory
import os
import re

DATA_PATH      = 'cameras'
DEFAULT_WIDTH  = 640
DEFAULT_HEIGHT = 480

class CameraRegistry(DataDirectory):
  def __init__(self):
    super(CameraRegistry, self).__init__(DATA_PATH)
    self.refresh()

  def refresh(self):
    self.dirs = {}
    for camera_id in os.listdir(self.path):
      camera_path = os.path.join(self.path, camera_id)
      if os.path.isdir(camera_path):
        self.dirs[camera_id] = CameraDirectory(camera_id)
    return self

  def __len__(self):
    return len(self.dirs)

  def __iter__(self):
    return self.dirs.values()

  def __contains__(self, id):
    return id in self.dirs

  def __getitem__(self, id):
    return self.dirs[id]

class CameraDirectory(DataDirectory):
  def __init__(self, id):
    super(CameraDirectory, self).__init__(DATA_PATH, id)
    self.id = id

  def feeds(self):
    for feed_name in os.listdir(self.path):
      feed_path = os.path.join(self.path, feed_name)
      if os.path.isfile(feed_path):
        try:
          feed = CameraFeed(self, path=feed_path)
        except:
          continue
        yield feed

  def __iter__(self):
    return self.feeds()

  def open_feed(self, **kwargs):
    if not 'channel' in kwargs:
      kwargs['channel'] = 'original'
    if not 'size' in kwargs:
      for feed in self:
        if feed.channel == kwargs['channel']:
          return feed
      return None
    if not 'mode' in kwargs:
      kwargs['mode'] = self.mode or 'r'
    return CameraFeed(self, **kwargs)

class CameraFeed:
  PATH_REGEXP = re.compile(r'(\d+)x(\d+).([a-z0-9_\+\-]+).(bgr|gray|hsv|yuyv)')

  def __init__(self, dir, path=None, size=None, channel='original', format='bgr', mode='r'):
    width, height = None, None
    if path:
      self.path = os.path.join(dir.path, path)
      match = self.PATH_REGEXP.match(os.path.basename(self.path))
      width, height, channel, format = int(match.group(1)), int(match.group(2)), match.group(3), match.group(4)
      size = width, height
    else:
      width, height = size
      self.path = os.path.join(dir.path, '{}x{}.{}.{}'.format(width, height, channel, format))
    self.channel = channel
    self.image = SharedImage(self.path, width=width, height=height, format=format, mode=mode)

  @property
  def size(self):
    return self.image.size

  @property
  def width(self):
    return self.image.width

  @property
  def height(self):
    return self.image.height

  @property
  def format(self):
    return self.image.format

  def snap(self, format=None):
    # TODO: eliminate unnecessary copies:
    if format is None:
      return self.image.copy()
    elif format == 'bgr':
      return self.image.copy().to_bgr()
    elif format == 'gray':
      return self.image.copy().to_gray()
    elif format == 'hsv':
      return self.image.copy().to_hsv()
    assert False
