# GetLogData

### 使用说明

<p>1. 将log文件夹拖到app中（注：先将少量log拖入进行验证）</p>

<p>2. 选择对应站别，或者使用temp内自定义的格式</p>

<p>3. Include框内填log中需要包含的字符串（如 TestResult : PASS），Exclude框内填需要排除的字符串（如 Uppdca: NO），多个条件则用"$"分隔开。最后会在满足条件的log中进行查找。</p>

<p>4. Start和End为搜索定位条件</p>

<ul>
    <li>Start和End框一一对应，通过Start和End定位截取字符串，多个条件用"$"分隔开</li>
    <li>单个条件以"++"分隔，前面为搜索关键字，后面为定位，（如 start中填"Duration++3"，end中填"s++"，则会在log"Duration : 2.789s"中截取到2.789），"++"之后的写负数则会先减去关键词本身的长度再做定位</li>
    <li>Start存在多个条件时必须按log内先后顺序进行排列</li>
    <li>每个条件在Format中以下标定位，从0开始</li>
    <li>特殊关键词占两个下标，具体格式见5</li>
</ul>

<p>5. 特殊关键词</p>
<table border="1" cellspacing="0" cellpadding="0">
    <tr>
        <td>Keyword</td>
        <td style="text-align:center">Start</td>
        <td style="text-align:center">End</td>
        <td style="text-align:center">Mark</td>
    </tr>
    <tr>
        <td>CheckUOP</td>
        <td>SET SN++-25$Func Call : Check_UOP++-25</td>
        <td>SET SN++-2$Func Call : Check_UOP++-2</td>
        <td>CheckUOP的前后时间</td>
    </tr>
    <tr>
        <td>Item[i]Query</td>
        <td>========== Start Test Item [i]++-25$Func Call: AEQuerySFC++-25</td>
        <td>========== Start Test Item [i]++-2$Func Call: AEQuerySFC++-2</td>
        <td>Item[i]中QuerySFC的时间</td>
    </tr>
    <tr>
        <td>Item[i]</td>
        <td>========== Start Test Item [i]++-25$========== Start Test Item [i+1]++-25</td>
        <td>========== Start Test Item [i]++-2$========== Start Test Item [i+1]++-2</td>
        <td>Item[i]的测试时间</td>
    </tr>
</table>

<p>6. Format为输出格式，需要先选定输出为.csv还是.plist</p>
<ul>
    <li>每一列以"$"分隔</li>
    <li>每一项格式为"(标题)内容",括号必须写，括号内为csv每一列标题</li>
    <li>内容以[i]表示，i为Start最终的下标（特殊关键词占两个）</li>
    <li>若内容格式为[1]to[2],则保存的数据为下标1和2两个时间点的时间差，所有在使用时需要保证截取的时间格式为"yyyy-MM-dd HH:mm:ss.SSS"</li>
    <li>输入plist建议在Format中只填一项，默认以"Source"数组保存</li>
</ul>

<p>7. 下方第一个图标为清空TextView内容，第二个为保存所写的配置，第三个为将拖入文件夹内的压缩包进行解压（会将原zip删除）</p>