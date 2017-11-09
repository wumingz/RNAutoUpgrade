/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, {Component} from 'react';
import {
    AppState,
    AppRegistry,
    StyleSheet,
    Text,
    View,
    Image,
    Alert,
    TouchableOpacity,
    InteractionManager
} from 'react-native';
// const test1 = require("./assets/icon1.png")
// const test2 = require("./assets/icon2.png")
// const test3 = require("./assets/icon3.png")
// const test4 = require("./assets/icon4.png")
// const test6 = require("./assets/icon6.png")
const test5 = require("./assets/icon5.png")
// const test7 = require("./assets/icon7.png")
// const test8 = require("./assets/icon8.png")
// const test9 = require("./assets/icon9.png")
import RNAutoupgradeTool,{isFirstTime,isRolledBack} from 'react-native-autoupdate';


export default class AutoUpgradeDemo extends Component {

    constructor(props){
        super(props);

        this.currentAppState = AppState.currentState;
    }

    componentWillMount(){

        // this.showAutoUpgradeInfo();

        AppState.addEventListener('change', this.handleAppStateChanged);
    }


    componentWillUnmount() {

        AppState.removeEventListener('change', this.handleAppStateChanged);
    }


    //代码回滚、模拟回滚测试
    showAutoUpgradeInfo() {
        if (isRolledBack) {
            Alert.alert('提示', '刚刚更新失败了,版本被回滚');
        } else if (isFirstTime) {
            Alert.alert('提示', '这是当前版本第一次启动,是否要模拟启动失败?将回滚到上一版本', [
                {text: '是', onPress: ()=>{throw new Error('模拟启动失败,请重启应用')}},
                {text: '否', onPress: ()=>{RNAutoupgradeTool.markSuccess()}},
            ]);
        };

    }

    componentDidMount() {
        // let test = {}
        // test.xxx.xxx = 0
        InteractionManager.runAfterInteractions(() => {
            if (isFirstTime) {
                //app热更新成功后首次加载时调用，避免回滚
                RNAutoupgradeTool.markSuccess();
            }

            this.startAutoUpgrade();
        });
    }


    //监听appStatus
    handleAppStateChanged = (nextAppStatus)=>{

        if (this.currentAppState.match(/background/) && nextAppStatus === 'active'){
            InteractionManager.runAfterInteractions(() => {
                this.startAutoUpgrade();
            })
        }

        this.currentAppState = nextAppStatus;
    }

    //开始进行自动更新
    startAutoUpgrade() {
        //参数：appkey
        RNAutoupgradeTool.checkAutoUpgradeWithAppkey('001d4fa0d4c9dacb011a515e44dc78f8');
    }


    onPress = ()=>{}

    render() {
        return (
            <View style={styles.container}>
                <Text style={styles.welcome}>
                    Welcome to React
                </Text>
                <Text style={styles.instructions}>
                    To get 12345689热特特特人生nnn-01
                </Text>
                {/*<Image source={test1} style={{width:100,height:100}}/>*/}
                {/*<Image source={test2} style={{width:100,height:100}}/>*/}
                {/*<Image source={test3} style={{width:100,height:100}}/>*/}
                {/*<Image source={test4} style={{width:100,height:100}}/>*/}
                {/*<Image source={test6} style={{width:100,height:100}}/>*/}
                <Image source={test5} style={{width:100,height:100}}/>
                {/*<Image source={test9} style={{width:100,height:100}}/>*/}
                {/*<Image source={test7} style={{width:100,height:100}}/>*/}
                {/*<Image source={test8} style={{width:100,height:100}}/>*/}
                {/*<Image source={test4} style={{width:100,height:100}}/>*/}
                <TouchableOpacity onPress = {this.onPress}>
                    <Text style={styles.instructions}>
                        请点击,{'\n'}
                        检查版本更新
                    </Text>
                </TouchableOpacity>
            </View>
        );
    }
} 

const styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#F5FCFF',
    },
    welcome: {
        fontSize: 20,
        textAlign: 'center',
        margin: 10,
    },
    instructions: {
        textAlign: 'center',
        color: '#333333',
        marginBottom: 5,
    },
});

AppRegistry.registerComponent('AutoUpgradeDemo', () => AutoUpgradeDemo);
