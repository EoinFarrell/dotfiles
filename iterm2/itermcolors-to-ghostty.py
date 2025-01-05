import xml.etree.ElementTree as ET

itermToGhosttyConfigLookup = {
  "Background Color": "background",
  "Cursor Color": "cursor-color",
  "Cursor Text Color": "cursor-text",
  "Foreground Color": "foreground",
  "Selected Text Color": "selection-foreground",
  "Selection Color": "selection-background",
}

def rgba_to_hex(r, g, b, a):
    return '#{:02X}{:02X}{:02X}'.format(int(r * 255), int(g * 255), int(b * 255))

def convertToGhosttyColor(color_name, hex_value):
    colorId = None
    if(color_name.startswith('Ansi')):
        colorId = 'palette = ' + color_name.split(' ')[1]
    else:
        colorId = itermToGhosttyConfigLookup.get(color_name)
        
    if(colorId != None):
        return colorId + "=" + hex_value

def printAsGhosttyColor(color_name, hex_value):
    ghosttyColor = convertToGhosttyColor(color_name, hex_value)
    if(ghosttyColor != None):
        print(ghosttyColor)

tree = ET.parse('/Users/eoin.farrell/Code/personal/dotfiles/iterm2/clovis-iterm-colour.itermcolors')
iterator = tree.getroot().find('dict')
i = 0

for element in iterator:
    if element.tag == 'key':
        color_name = element.text
        color_dict = iterator[i+1]
        r = float(color_dict.find('real[4]').text)
        g = float(color_dict.find('real[3]').text)
        b = float(color_dict.find('real[2]').text)
        a = float(color_dict.find('real[1]').text)
        hex_value = rgba_to_hex(r, g, b, a)
        printAsGhosttyColor(color_name, hex_value)
    i += 1