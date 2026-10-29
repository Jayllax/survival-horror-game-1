# Square and rectangular alleyway light

Drag **`scenes/objects/lighting/alley_light.tscn`** into your level. It is a normal editor-visible **PointLight2D** with a square, softly feathered texture. Place its root at the **center of the area you want lit**. Its starting square is about **160×160 world pixels**.

Select the placed light and adjust:

- **Texture Scale:** change the whole light's size uniformly.
- **Transform → Scale:** change X and Y separately to make a rectangle. For example, (0.5, 1.5) gives roughly 80×240 world pixels at the supplied Texture Scale.
- **Transform → Rotation:** turn the rectangle if needed.
- **Color / Energy:** choose the tint and brightness.
- **Offset:** shift the illuminated texture relative to the light's origin. Leave it at (0,0) for a centered square.
- **Range → Z Max:** starts at 1, matching your flashlight's current depth limit. Objects with a higher effective Z Index are excluded. Change the range to suit the layers in your scene.

The texture is **`art/lights/square_beam.tres`**. To use it on a light you already placed, select its PointLight2D, choose **Texture → Load**, and select that resource. It is a native Godot **GradientTexture2D**, so there is no PNG to export. It has straight square boundaries with a soft fade toward the edges, rather than a widening cone.

You can expand Texture → Gradient in the Inspector to edit the falloff. Use **Make Unique** first if the change should affect only one placed light; otherwise all lights sharing the resource change. PointLight2D Color and Energy can be changed per instance without making its texture unique.

Use the scene's existing **CanvasModulate** for ambient darkness. Blocking the light requires **LightOccluder2D** shapes; collision shapes alone do not block light. This uses Godot lighting to illuminate surfaces. A fog/sprite layer is needed if you also want a visible shaft through empty air.

This asset is ready to place; it has not been inserted into your authored levels. Your player flashlight and existing lamp textures are unchanged.
