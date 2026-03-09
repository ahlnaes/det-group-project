using UnityEngine;

public class NoiseTexGen : MonoBehaviour
{
    void Start()
    {
        int size = 64;
        Texture2D tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
        for (int y = 0; y < size; y++)
        for (int x = 0; x < size; x++)
        {
            tex.SetPixel(x, y, new Color(
                Random.value,
                Random.value,
                Random.value,
                1f
            ));
        }
        tex.Apply();
        byte[] bytes = tex.EncodeToPNG();
        System.IO.File.WriteAllBytes("Assets/Shaders, materials, textures/Textures/noise/noise4.png", bytes);
        Debug.Log("Done");
    }
}