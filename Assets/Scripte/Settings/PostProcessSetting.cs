using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

[Serializable]
public class PostProcessSetting
{
    public BloomData bloomdata;

    [Serializable]
    public struct BloomData
    {
        public bool bloomstate;
        public Material selectmask;
        public Material bloom;
    };
}
