import pygame


class Spritesheet(object):
    def __init__(self, filename):
        try:
            # Load image - don't convert here, will do per-sprite
            self.sheet = pygame.image.load(filename)
        except pygame.error as e:
            print("Unable to load spritesheet image:", filename)
            print("Error:", e)
            raise SystemExit

    def image_at(self, x, y, scalingfactor, colorkey=None, ignoreTileSize=False,
                 xTileSize=16, yTileSize=16):
        if ignoreTileSize:
            rect = pygame.Rect((x, y, xTileSize, yTileSize))
        else:
            rect = pygame.Rect((x * xTileSize, y * yTileSize, xTileSize, yTileSize))
        
        # Create surface with alpha channel
        image = pygame.Surface(rect.size, pygame.SRCALPHA)
        image.blit(self.sheet, (0, 0), rect)
        
        if colorkey is not None:
            if colorkey == -1:
                # Use top-left pixel as colorkey
                colorkey = image.get_at((0, 0))
            image.set_colorkey(colorkey, pygame.RLEACCEL)
        
        # Scale with alpha preservation
        return pygame.transform.scale(
            image, (xTileSize * scalingfactor, yTileSize * scalingfactor)
        )
